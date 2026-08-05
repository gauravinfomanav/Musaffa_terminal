import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:musaffa_terminal/models/auth_models.dart';

/// Persists JWT + lightweight user profile for session restore.
class AuthTokenStore {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  static const _expiresAtKey = 'auth_expires_at';

  final FlutterSecureStorage _storage;

  AuthTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> saveSession({
    required String token,
    required AuthUser user,
    String? expiresAt,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
    if (expiresAt != null) {
      await _storage.write(key: _expiresAtKey, value: expiresAt);
    }
  }

  Future<AuthUser?> getUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUser(AuthUser user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _userKey),
      _storage.delete(key: _expiresAtKey),
    ]);
  }
}
