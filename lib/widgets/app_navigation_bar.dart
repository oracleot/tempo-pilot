import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tempo_pilot/features/ai_chat/providers/ai_chat_providers.dart';

/// Shared bottom navigation used across primary tabs.
class AppNavigationBar extends ConsumerWidget {
  const AppNavigationBar({super.key, required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiChatEnabledAsync = ref.watch(aiChatEnabledProvider);
    final isAiChatEnabled = aiChatEnabledAsync.maybeWhen(
      data: (value) => value,
      orElse: () => false,
    );
    final isCheckingAccess = aiChatEnabledAsync.isLoading;
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        if (index == selectedIndex) {
          return;
        }
        final router = GoRouter.maybeOf(context);
        switch (index) {
          case 0:
            router?.go('/timer');
            break;
          case 1:
            router?.go('/planner/free');
            break;
          case 2:
            if (isCheckingAccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Checking AI chat access…'),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            if (!isAiChatEnabled) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('AI chat is limited to tester accounts.'),
                  duration: Duration(seconds: 3),
                ),
              );
              return;
            }
            router?.go('/ai');
            break;
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.timer), label: 'Timer'),
        NavigationDestination(
          icon: Icon(Icons.calendar_today),
          label: 'Planner',
        ),
        NavigationDestination(icon: Icon(Icons.chat), label: 'AI Chat'),
      ],
    );
  }
}
