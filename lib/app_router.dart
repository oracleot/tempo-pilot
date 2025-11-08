import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tempo_pilot/features/ai_chat/ui/chat_screen.dart';
import 'package:tempo_pilot/features/auth/login_page.dart';
import 'package:tempo_pilot/features/timer/timer_shell.dart';
import 'package:tempo_pilot/features/planner/free_blocks/free_blocks_screen.dart';
import 'package:tempo_pilot/features/calendar/picker/calendar_picker_screen.dart';
import 'package:tempo_pilot/providers/auth_provider.dart';

/// Global navigator key for accessing navigation outside of widget context.
/// Used by notification tap callbacks to navigate to specific routes.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// GoRouter configuration with auth guard.
/// Implements redirect logic to protect authenticated routes.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final returnPath = ref.watch(returnPathProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    debugLogDiagnostics: true,
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authState;
      final isOnLoginPage = state.matchedLocation == '/login';

      // If not logged in and not on login page, redirect to login with return path
      if (!isLoggedIn && !isOnLoginPage) {
        return '/login?from=${Uri.encodeComponent(state.matchedLocation)}';
      }

      // If logged in and on login page, redirect to intended destination
      if (isLoggedIn && isOnLoginPage) {
        // Check for return path from deep link, then fallback to query param
        final destination =
            returnPath ?? state.uri.queryParameters['from'] ?? '/timer';

        // Clear the return path after using it
        if (returnPath != null) {
          Future.microtask(
            () => ref.read(returnPathProvider.notifier).state = null,
          );
        }

        return destination;
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/timer',
        name: 'timer',
        builder: (context, state) => const TimerShell(),
      ),
      GoRoute(
        path: '/planner/free',
        name: 'planner-free',
        builder: (context, state) => const FreeBlocksScreen(),
      ),
      GoRoute(
        path: '/settings/calendars',
        name: 'settings-calendars',
        builder: (context, state) => const CalendarPickerScreen(),
      ),
      GoRoute(
        path: '/ai',
        name: 'ai-chat',
        builder: (context, state) => const AiChatScreen(),
      ),
      GoRoute(path: '/', redirect: (context, state) => '/timer'),
    ],
  );
});
