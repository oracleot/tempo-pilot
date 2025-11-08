import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo_pilot/features/calendar/services/calendar_permission_service.dart';
import 'package:tempo_pilot/features/calendar/providers/calendar_providers.dart';
import 'package:tempo_pilot/core/services/analytics_service.dart';
import 'package:tempo_pilot/providers/analytics_provider.dart';

/// Widget that displays a permission rationale and handles the permission request flow.
class CalendarPermissionPrompt extends ConsumerStatefulWidget {
  const CalendarPermissionPrompt({
    super.key,
    this.onPermissionGranted,
    this.onPermissionDenied,
  });

  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;

  @override
  ConsumerState<CalendarPermissionPrompt> createState() =>
      _CalendarPermissionPromptState();
}

class _CalendarPermissionPromptState
    extends ConsumerState<CalendarPermissionPrompt> {
  bool _hasLoggedPrompt = false;

  void _logPrompt(AnalyticsService analytics) {
    if (_hasLoggedPrompt) {
      return;
    }
    _hasLoggedPrompt = true;
    analytics.logCalendarPermissionPromptShown();
  }

  @override
  Widget build(BuildContext context) {
    final permissionStatusAsync = ref.watch(calendarPermissionStatusProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final controller = ref.read(calendarPermissionStatusProvider.notifier);

    return permissionStatusAsync.when(
      data: (status) {
        if (status == CalendarPermissionStatus.granted) {
          // Reset guard so future prompts can log again if permission changes.
          _hasLoggedPrompt = false;
          return _PermissionGrantedView(onContinue: widget.onPermissionGranted);
        } else if (status == CalendarPermissionStatus.permanentlyDenied) {
          _logPrompt(analytics);
          return _PermissionDeniedView(
            isPermanent: true,
            onOpenSettings: () async {
              await controller.openSettings();
            },
            onCancel: widget.onPermissionDenied,
          );
        } else {
          _logPrompt(analytics);

          return _PermissionRationaleView(
            onRequestPermission: () async {
              final newStatus = await controller.requestPermission();

              // Log the result
              if (newStatus == CalendarPermissionStatus.granted) {
                analytics.logCalendarPermissionGranted();
                widget.onPermissionGranted?.call();
              } else {
                analytics.logCalendarPermissionDenied(
                  permanent:
                      newStatus == CalendarPermissionStatus.permanentlyDenied,
                );
                widget.onPermissionDenied?.call();
              }
            },
            onCancel: widget.onPermissionDenied,
          );
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

/// Rationale view shown before requesting permission.
class _PermissionRationaleView extends StatelessWidget {
  const _PermissionRationaleView({
    required this.onRequestPermission,
    this.onCancel,
  });

  final VoidCallback onRequestPermission;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.calendar_today,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Connect Your Calendar',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Tempo Pilot reads your calendar to find free time for focus sessions.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Your calendar details stay on your device and are never uploaded.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: onRequestPermission,
            child: const Text('Allow Calendar Access'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              onCancel?.call();
            },
            child: const Text('Not Now'),
          ),
        ],
      ),
    );
  }
}

/// View shown when permission is permanently denied.
class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView({
    required this.isPermanent,
    required this.onOpenSettings,
    this.onCancel,
  });

  final bool isPermanent;
  final VoidCallback onOpenSettings;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 24),
          Text(
            'Calendar Access Needed',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            isPermanent
                ? 'You\'ve denied calendar permission. Please enable it in Settings to use this feature.'
                : 'Calendar access is required to find free time for focus sessions.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: onOpenSettings,
            child: const Text('Open Settings'),
          ),
          const SizedBox(height: 12),
          if (onCancel != null)
            TextButton(onPressed: onCancel, child: const Text('Cancel')),
        ],
      ),
    );
  }
}

/// View shown when permission is already granted.
class _PermissionGrantedView extends StatelessWidget {
  const _PermissionGrantedView({this.onContinue});

  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.check_circle, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'Calendar Connected',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your calendars are connected. You can now see free time slots.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (onContinue != null)
            FilledButton(onPressed: onContinue, child: const Text('Continue')),
        ],
      ),
    );
  }
}
