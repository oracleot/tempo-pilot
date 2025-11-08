import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo_pilot/data/local/app_database.dart';

/// Provider for the application database instance.
///
/// This provider must be overridden in main.dart with the actual database instance
/// after it has been initialized asynchronously. It throws an error if accessed
/// before initialization to catch setup issues early.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'appDatabaseProvider must be overridden in main.dart with initialized database',
  );
});

/// Provider for the FocusSessionDao.
///
/// Automatically provides access to the DAO by watching the database provider.
/// Use this in features that need to interact with focus session data.
final focusSessionDaoProvider = Provider<FocusSessionDao>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.focusSessionDao;
});
