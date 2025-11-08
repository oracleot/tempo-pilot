import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tempo_pilot/app_router.dart';
import 'package:tempo_pilot/core/config/supabase_config.dart';
import 'package:tempo_pilot/core/services/notification_service.dart';
import 'package:tempo_pilot/core/storage/secure_local_storage.dart';
import 'package:tempo_pilot/data/local/app_database.dart';
import 'package:tempo_pilot/features/timer/providers/timer_provider.dart';
import 'package:tempo_pilot/providers/auth_provider.dart';
import 'package:tempo_pilot/providers/database_provider.dart';
import 'package:tempo_pilot/providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with secure session storage
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(localStorage: SecureLocalStorage()),
  );

  // Initialize encrypted database on background isolate
  final database = await AppDatabase.open();

  // Initialize SharedPreferences for timer state persistence
  final prefs = await SharedPreferences.getInstance();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize(
    onNotificationTap: () {
      // Navigate to timer screen when notification is tapped
      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        GoRouter.of(context).go('/timer');
      }
    },
  );

  // Request notification permission on first launch
  await notificationService.requestPermission();

  // Create ProviderContainer to initialize deep link service
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      sharedPreferencesProvider.overrideWithValue(prefs),
      notificationServiceProvider.overrideWithValue(notificationService),
    ],
  );

  // Initialize deep link handling for magic link auth
  await container.read(deepLinkServiceProvider).initialize();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TempoPilotApp(),
    ),
  );
}

class TempoPilotApp extends ConsumerWidget {
  const TempoPilotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Listen for auth errors and show SnackBar
    ref.listen<String?>(authErrorProvider, (previous, error) {
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
        // Clear error after showing
        Future.microtask(
          () => ref.read(authErrorProvider.notifier).state = null,
        );
      }
    });

    return MaterialApp.router(
      title: 'Tempo Pilot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
