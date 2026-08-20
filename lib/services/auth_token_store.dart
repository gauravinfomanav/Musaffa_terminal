import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:musaffa_terminal/models/auth_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists JWT + lightweight user profile for session restore.
class AuthTokenStore {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  static const _expiresAtKey = 'auth_expires_at';
  static const _fallbackPrefix = 'auth_fallback_';

  final FlutterSecureStorage _storage;
  SharedPreferences? _prefs;
  bool _preferFallback = false;

  AuthTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _write(String key, String value) async {
    if (_preferFallback) {
      final prefs = await _getPrefs();
      await prefs.setString('$_fallbackPrefix$key', value);
      return;
    }

    try {
      await _storage.write(key: key, value: value);
    } catch (e, stack) {
      debugPrint('AuthTokenStore: secure write failed, using fallback: $e');
      debugPrint('$stack');
      _preferFallback = true;
      final prefs = await _getPrefs();
      await prefs.setString('$_fallbackPrefix$key', value);
    }
  }

  Future<String?> _read(String key) async {
    if (_preferFallback) {
      final prefs = await _getPrefs();
      return prefs.getString('$_fallbackPrefix$key');
    }

    try {
      final value = await _storage.read(key: key);
      if (value != null) return value;
    } catch (e, stack) {
      debugPrint('AuthTokenStore: secure read failed, using fallback: $e');
      debugPrint('$stack');
      _preferFallback = true;
    }

    final prefs = await _getPrefs();
    return prefs.getString('$_fallbackPrefix$key');
  }

  Future<void> _delete(String key) async {
    if (!_preferFallback) {
      try {
        await _storage.delete(key: key);
      } catch (_) {
        _preferFallback = true;
      }
    }
    final prefs = await _getPrefs();
    await prefs.remove('$_fallbackPrefix$key');
  }

  Future<String?> getToken() => _read(_tokenKey);

  Future<void> saveSession({
    required String token,
    required AuthUser user,
    String? expiresAt,
  }) async {
    await _write(_tokenKey, token);
    await _write(_userKey, jsonEncode(user.toJson()));
    if (expiresAt != null) {
      await _write(_expiresAtKey, expiresAt);
    }
  }

  Future<AuthUser?> getUser() async {
    final raw = await _read(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUser(AuthUser user) async {
    await _write(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> clear() async {
    await Future.wait([
      _delete(_tokenKey),
      _delete(_userKey),
      _delete(_expiresAtKey),
    ]);
  }
}
