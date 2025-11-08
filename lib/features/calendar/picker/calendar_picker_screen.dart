import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo_pilot/features/calendar/models/calendar_source.dart';
import 'package:tempo_pilot/features/calendar/picker/calendar_picker_view_model.dart';
import 'package:tempo_pilot/features/calendar/picker/widgets/calendar_row.dart';
import 'package:tempo_pilot/features/calendar/providers/calendar_providers.dart';
import 'package:tempo_pilot/features/calendar/services/calendar_permission_service.dart';
import 'package:tempo_pilot/providers/analytics_provider.dart';

/// Screen that lets the user include or exclude device calendars from the app.
class CalendarPickerScreen extends ConsumerStatefulWidget {
  const CalendarPickerScreen({super.key});

  @override
  ConsumerState<CalendarPickerScreen> createState() =>
      _CalendarPickerScreenState();
}

class _CalendarPickerScreenState extends ConsumerState<CalendarPickerScreen> {
  static const _searchDebounce = Duration(milliseconds: 250);

  late final TextEditingController _searchController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(analyticsServiceProvider).logCalendarPickerOpened();

      // Trigger calendar discovery and persistence after permission check
      _ensureCalendarsDiscovered();
    });
  }

  /// Discovers and persists calendars if permission is granted but no calendars exist yet
  Future<void> _ensureCalendarsDiscovered() async {
    final permissionStatus = await ref.read(
      calendarPermissionStatusProvider.future,
    );
    if (permissionStatus != CalendarPermissionStatus.granted) {
      return;
    }

    // Check if we already have persisted calendars
    final persisted = await ref.read(persistedCalendarSourcesProvider.future);
    if (persisted.isNotEmpty) {
      return; // Already discovered and persisted
    }

    // Discover and persist calendars
    try {
      final discovered = await ref.read(
        discoveredCalendarSourcesProvider.future,
      );
      if (discovered.isEmpty) {
        return; // No calendars to persist
      }

      final persist = ref.read(persistCalendarSourcesProvider);
      await persist(discovered);

      // Refresh the persisted list
      ref.invalidate(persistedCalendarSourcesProvider);
    } catch (error, stackTrace) {
      ref
          .read(analyticsServiceProvider)
          .logException(
            error,
            stackTrace,
            context: 'calendar_discovery_initial',
          );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final permissionStatusAsync = ref.watch(calendarPermissionStatusProvider);
    final pickerStateAsync = ref.watch(calendarPickerStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendars')),
      body: permissionStatusAsync.when(
        data: (permissionStatus) {
          if (permissionStatus == CalendarPermissionStatus.granted) {
            return pickerStateAsync.when(
              data: (state) => _buildGrantedView(context, state),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _ErrorView(
                message: 'Unable to load calendars',
                details: error.toString(),
                onRetry: () {
                  ref.invalidate(persistedCalendarSourcesProvider);
                },
              ),
            );
          }

          return _PermissionRequiredView(
            status: permissionStatus,
            onRequestPermission: _handlePermissionRequest,
            onOpenSettings: _handleOpenSettings,
            onRefreshStatus: _handleRefreshPermission,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorView(
          message: 'Unable to read calendar permission status',
          details: error.toString(),
          onRetry: () {
            ref.invalidate(calendarPermissionStatusProvider);
          },
        ),
      ),
    );
  }

  Widget _buildGrantedView(BuildContext context, CalendarPickerState state) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              Icon(Icons.event_available, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Included calendars',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${state.includedCount} of ${state.totalCount}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search calendars',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: state.query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    ),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Builder(
            builder: (context) {
              if (state.totalCount == 0) {
                return _EmptyCalendarsView(
                  onRefresh: () {
                    ref.invalidate(persistedCalendarSourcesProvider);
                    _handleRefreshPermission();
                  },
                );
              }

              if (state.isSearching && !state.hasResults) {
                return _NoSearchResultsView(onClearSearch: _clearSearch);
              }

              return ListView.separated(
                itemCount: state.filteredSources.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, index) {
                  final source = state.filteredSources[index];
                  return CalendarPickerRow(
                    key: ValueKey(source.id),
                    source: source,
                    onToggle: (value) => _handleToggle(source, value),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _handleToggle(CalendarSource source, bool include) async {
    final update = ref.read(updateCalendarIncludedProvider);
    final analytics = ref.read(analyticsServiceProvider);

    try {
      await update(source.id, include);
      analytics.logCalendarPickerToggleIncluded(
        included: include,
        isPrimary: source.isPrimary,
        hasAccountName:
            source.accountName != null && source.accountName!.isNotEmpty,
      );
    } catch (error, stackTrace) {
      analytics.logException(
        error,
        stackTrace,
        context: 'calendar_picker_toggle',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update calendar. Please retry.'),
        ),
      );
    }
  }

  void _onSearchChanged(String rawValue) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_searchDebounce, () {
      ref.read(calendarPickerSearchQueryProvider.notifier).state = rawValue;

      final analytics = ref.read(analyticsServiceProvider);
      final state = ref.read(calendarPickerStateProvider);
      final resultCount = state.maybeWhen(
        data: (data) => data.filteredSources.length,
        orElse: () => 0,
      );
      analytics.logCalendarPickerSearch(
        queryLength: rawValue.trim().length,
        resultsCount: resultCount,
      );
    });
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    ref.read(calendarPickerSearchQueryProvider.notifier).state = '';

    final analytics = ref.read(analyticsServiceProvider);
    final state = ref.read(calendarPickerStateProvider);
    final resultCount = state.maybeWhen(
      data: (data) => data.filteredSources.length,
      orElse: () => 0,
    );
    analytics.logCalendarPickerSearch(
      queryLength: 0,
      resultsCount: resultCount,
    );
  }

  Future<void> _handlePermissionRequest() async {
    final controller = ref.read(calendarPermissionStatusProvider.notifier);
    final analytics = ref.read(analyticsServiceProvider);

    final status = await controller.requestPermission();
    if (status == CalendarPermissionStatus.granted) {
      analytics.logCalendarPermissionGranted();

      // Discover and persist calendars after granting permission
      await _ensureCalendarsDiscovered();
    } else {
      analytics.logCalendarPermissionDenied(
        permanent: status == CalendarPermissionStatus.permanentlyDenied,
      );
    }
  }

  Future<void> _handleOpenSettings() async {
    final controller = ref.read(calendarPermissionStatusProvider.notifier);
    await controller.openSettings();
  }

  void _handleRefreshPermission() {
    final controller = ref.read(calendarPermissionStatusProvider.notifier);
    controller.refresh();
  }
}

class _PermissionRequiredView extends StatelessWidget {
  const _PermissionRequiredView({
    required this.status,
    required this.onRequestPermission,
    required this.onOpenSettings,
    required this.onRefreshStatus,
  });

  final CalendarPermissionStatus status;
  final Future<void> Function() onRequestPermission;
  final Future<void> Function() onOpenSettings;
  final VoidCallback onRefreshStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPermanent = status == CalendarPermissionStatus.permanentlyDenied;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Calendar access is required',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isPermanent
                  ? 'Enable calendar access in system settings to choose calendars.'
                  : 'Grant calendar permission to choose which calendars to include.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                if (isPermanent) {
                  await onOpenSettings();
                } else {
                  await onRequestPermission();
                }
                onRefreshStatus();
              },
              child: Text(isPermanent ? 'Open Settings' : 'Allow Access'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRefreshStatus,
              child: const Text('Check again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCalendarsView extends StatelessWidget {
  const _EmptyCalendarsView({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No calendars discovered yet',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Once calendars are discovered on this device, they will appear here.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(onPressed: onRefresh, child: const Text('Refresh')),
          ],
        ),
      ),
    );
  }
}

class _NoSearchResultsView extends StatelessWidget {
  const _NoSearchResultsView({required this.onClearSearch});

  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No calendars match your search',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search or clear the field to browse all calendars.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: onClearSearch,
              child: const Text('Clear search'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.details,
    required this.onRetry,
  });

  final String message;
  final String details;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              details,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
