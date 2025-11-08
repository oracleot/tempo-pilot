import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Secure LocalStorage implementation using flutter_secure_storage.
///
/// This implementation persists Supabase sessions in encrypted storage
/// on the device, ensuring that user sessions are maintained securely
/// across app restarts.
///
/// Based on the Supabase Flutter README example for custom secure storage.
class SecureLocalStorage extends LocalStorage {
  SecureLocalStorage() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> initialize() async {
    // No initialization needed for FlutterSecureStorage
  }

  @override
  Future<String?> accessToken() async {
    return _storage.read(key: supabasePersistSessionKey);
  }

  @override
  Future<bool> hasAccessToken() async {
    return _storage.containsKey(key: supabasePersistSessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    return _storage.write(
      key: supabasePersistSessionKey,
      value: persistSessionString,
    );
  }

  @override
  Future<void> removePersistedSession() async {
    return _storage.delete(key: supabasePersistSessionKey);
  }
}
