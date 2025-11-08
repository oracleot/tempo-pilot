import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tempo_pilot/features/timer/models/timer_state.dart';
import 'package:tempo_pilot/features/timer/providers/timer_provider.dart';
import 'package:tempo_pilot/providers/auth_provider.dart';
import 'package:tempo_pilot/widgets/app_navigation_bar.dart';

/// Timer page with configurable focus/break presets.
///
/// Supports start, pause, resume, and reset operations.
/// Handles app lifecycle to reconcile time after backgrounding.
class TimerShell extends ConsumerStatefulWidget {
  const TimerShell({super.key});

  @override
  ConsumerState<TimerShell> createState() => _TimerShellState();
}

class _TimerShellState extends ConsumerState<TimerShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reconcile timer state when app returns to foreground
      ref.read(timerProvider.notifier).reconcile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final notifier = ref.read(timerProvider.notifier);
    final focusOptions = TimerNotifier.focusDurationOptions;
    final selectedFocus = focusOptions.contains(timerState.focusDurationSetting)
        ? timerState.focusDurationSetting
        : focusOptions.last;
    final derivedBreak = TimerNotifier.deriveBreakDuration(selectedFocus);
    final canEditPreset = timerState.status == TimerStatus.idle;
    final authService = ref.watch(authServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/settings/calendars');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Phase indicator
            Text(
              timerState.phase == TimerPhase.focus
                  ? 'Focus Session'
                  : 'Break Time',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: timerState.phase == TimerPhase.focus
                    ? Colors.red.shade700
                    : Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Focus duration',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Duration>(
                    initialValue: selectedFocus,
                    items: [
                      for (final option in focusOptions)
                        DropdownMenuItem<Duration>(
                          value: option,
                          child: Text(_formatPresetLabel(option)),
                        ),
                    ],
                    onChanged: canEditPreset
                        ? (value) {
                            if (value != null && value != selectedFocus) {
                              notifier.updateFocusDuration(value);
                            }
                          }
                        : null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Break duration adjusts automatically: ${_formatPresetLabel(derivedBreak)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Time display
            Text(
              _formatDuration(
                timerState.remaining ?? timerState.targetDuration,
              ),
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 48),

            // Control buttons
            _buildControls(context, timerState, notifier),
          ],
        ),
      ),
      bottomNavigationBar: const AppNavigationBar(selectedIndex: 0),
    );
  }

  Widget _buildControls(
    BuildContext context,
    TimerState timerState,
    TimerNotifier notifier,
  ) {
    switch (timerState.status) {
      case TimerStatus.idle:
        return ElevatedButton.icon(
          onPressed: () => notifier.start(),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Focus'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
        );

      case TimerStatus.running:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => notifier.pause(),
              icon: const Icon(Icons.pause),
              label: const Text('Pause'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: () => notifier.reset(),
              icon: const Icon(Icons.stop),
              label: const Text('Reset'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        );

      case TimerStatus.paused:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => notifier.resume(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Resume'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: () => notifier.reset(),
              icon: const Icon(Icons.stop),
              label: const Text('Reset'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        );

      case TimerStatus.completed:
        // Show different button based on which phase just completed
        if (timerState.phase == TimerPhase.focus) {
          return Column(
            children: [
              const Text(
                '🎉 Focus session complete!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => notifier.startBreak(),
                icon: const Icon(Icons.coffee),
                label: const Text('Start Break'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => notifier.reset(),
                icon: const Icon(Icons.refresh),
                label: const Text('Skip Break'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              const Text(
                '✨ Break complete!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => notifier.reset(),
                icon: const Icon(Icons.refresh),
                label: const Text('Start New Session'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          );
        }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatPresetLabel(Duration duration) {
    if (duration.inMinutes >= 1) {
      if (duration.inMinutes % 60 == 0 && duration.inHours >= 1) {
        return '${duration.inHours} hr';
      }
      return '${duration.inMinutes} min';
    }
    return '${duration.inSeconds} sec';
  }
}
