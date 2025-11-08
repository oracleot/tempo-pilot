import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo_pilot/data/repositories/focus_session_repository.dart';
import 'package:tempo_pilot/providers/auth_provider.dart';
import 'package:tempo_pilot/providers/database_provider.dart';

/// Provider for the FocusSessionRepository.
///
/// Automatically wires the repository with the necessary DAO and current user ID.
/// Throws an error if accessed while user is not authenticated.
final focusSessionRepositoryProvider = Provider<FocusSessionRepository>((ref) {
  final dao = ref.watch(focusSessionDaoProvider);
  final authService = ref.watch(authServiceProvider);

  final userId = authService.currentUser?.id;
  if (userId == null) {
    throw StateError(
      'Cannot create FocusSessionRepository: user not authenticated',
    );
  }

  return FocusSessionRepository(dao: dao, userId: userId);
});
