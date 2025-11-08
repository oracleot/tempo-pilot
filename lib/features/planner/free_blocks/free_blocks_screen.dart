import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tempo_pilot/features/calendar/logic/free_busy_deriver.dart';
import 'package:tempo_pilot/features/calendar/providers/calendar_providers.dart';
import 'package:tempo_pilot/features/calendar/services/calendar_permission_service.dart';
import 'package:tempo_pilot/features/calendar/widgets/calendar_permission_prompt.dart';
import 'package:tempo_pilot/features/planner/free_blocks/free_blocks_controller.dart';
import 'package:tempo_pilot/features/planner/free_blocks/widgets/free_block_tile.dart';
import 'package:tempo_pilot/providers/analytics_provider.dart';
import 'package:tempo_pilot/widgets/app_navigation_bar.dart';

enum FreeBlockTab { today, week }

class FreeBlocksScreen extends ConsumerStatefulWidget {
  const FreeBlocksScreen({super.key});

  @override
  ConsumerState<FreeBlocksScreen> createState() => _FreeBlocksScreenState();
}

class _FreeBlocksScreenState extends ConsumerState<FreeBlocksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).logEvent('free_blocks_view_opened');
    });
  }

  @override
  Widget build(BuildContext context) {
    final permissionStatus = ref.watch(calendarPermissionStatusProvider);

    return permissionStatus.when(
      data: (status) {
        if (status != CalendarPermissionStatus.granted) {
          return Scaffold(
            appBar: AppBar(title: const Text('Planner')),
            body: const Padding(
              padding: EdgeInsets.all(16),
              child: CalendarPermissionPrompt(),
            ),
            bottomNavigationBar: const AppNavigationBar(selectedIndex: 1),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Planner'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: "Today"),
                  Tab(text: "This Week"),
                ],
              ),
            ),
            body: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Showing available time blocks for focus sessions',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  child: TabBarView(
                    children: [
                      _FreeBlocksTab(view: FreeBlockTab.today),
                      _FreeBlocksTab(view: FreeBlockTab.week),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: const AppNavigationBar(selectedIndex: 1),
          ),
        );
      },
      loading: () => const _LoadingScaffold(),
      error: (error, stackTrace) => _ErrorScaffold(error: error),
    );
  }
}

class _FreeBlocksTab extends ConsumerWidget {
  const _FreeBlocksTab({required this.view});

  final FreeBlockTab view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = view == FreeBlockTab.today
        ? filteredFreeBlocksTodayProvider
        : filteredFreeBlocksWeekProvider;

    final blocksAsync = ref.watch(provider);
    final controllerState = ref.watch(freeBlocksControllerProvider);

    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: controllerState.isLoading
              ? const LinearProgressIndicator()
              : const SizedBox.shrink(),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              try {
                await ref.read(freeBlocksControllerProvider.notifier).refresh();
              } catch (_) {
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Refresh failed. Please try again.'),
                  ),
                );
              }
            },
            child: blocksAsync.when(
              data: (blocks) => _FreeBlocksList(view: view, blocks: blocks),
              loading: () => const _FreeBlocksLoadingView(),
              error: (error, stackTrace) => _FreeBlocksErrorView(error: error),
            ),
          ),
        ),
      ],
    );
  }
}

class _FreeBlocksList extends ConsumerWidget {
  const _FreeBlocksList({required this.view, required this.blocks});

  final FreeBlockTab view;
  final List<TimeInterval> blocks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final includedCalendarsAsync = ref.watch(includedCalendarSourcesProvider);
    final calendarData = includedCalendarsAsync.whenOrNull(
      data: (value) => value,
    );
    final hasCalendars = calendarData?.isNotEmpty ?? true;

    if (!hasCalendars) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          _EmptyState(view: view, hasCalendars: false),
        ],
      );
    }

    if (blocks.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          _EmptyState(view: view, hasCalendars: true),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: blocks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final interval = blocks[index];
        return Material(
          elevation: 1,
          borderRadius: BorderRadius.circular(12),
          child: FreeBlockTile(
            interval: interval,
            showDayLabel: view == FreeBlockTab.week,
          ),
        );
      },
    );
  }
}

class _FreeBlocksLoadingView extends StatelessWidget {
  const _FreeBlocksLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _FreeBlocksErrorView extends ConsumerWidget {
  const _FreeBlocksErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 120),
      children: [
        Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
          size: 40,
        ),
        const SizedBox(height: 16),
        Text(
          'Something went wrong loading your free time.',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '$error',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Center(
          child: FilledButton.icon(
            onPressed: () async {
              try {
                await ref.read(freeBlocksControllerProvider.notifier).refresh();
              } catch (_) {
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Refresh failed. Please try again.'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.view, required this.hasCalendars});

  final FreeBlockTab view;
  final bool hasCalendars;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final copy = hasCalendars
        ? (view == FreeBlockTab.today
              ? 'No free blocks left today. Nice work!'
              : 'No free blocks detected this week.')
        : 'No calendars are included. Add one to see your open time.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Icon(
            hasCalendars ? Icons.stream : Icons.calendar_today_outlined,
            color: theme.colorScheme.primary,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            copy,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (!hasCalendars)
            FilledButton(
              onPressed: () {
                context.push('/settings/calendars');
              },
              child: const Text('Manage calendars'),
            ),
        ],
      ),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planner')),
      body: const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: const AppNavigationBar(selectedIndex: 1),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planner')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'We couldn\'t load your planner.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('$error', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppNavigationBar(selectedIndex: 1),
    );
  }
}
