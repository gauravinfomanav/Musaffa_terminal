import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:musaffa_terminal/models/auth_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists JWT + lightweight user profile for session restore.
///
/// Uses [FlutterSecureStorage] first, with a SharedPreferences fallback when
/// the secure backend fails (common on some Windows setups). Reads/writes must
/// always keep both backends in sync on clear — otherwise Windows can keep a
/// JWT in secure storage after logout, and the next cold start logs the user
/// back in.
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
              wOptions: WindowsOptions(),
            );

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _write(String key, String value) async {
    if (_preferFallback) {
      final prefs = await _getPrefs();
      await prefs.setString('$_fallbackPrefix$key', value);
      // Best-effort: remove any stale secure copy so logout cannot resurrect it.
      await _deleteSecureQuietly(key);
      return;
    }

    try {
      await _storage.write(key: key, value: value);
      // Successful secure write — drop any leftover fallback from an older
      // failure path so the two stores cannot disagree after logout.
      final prefs = await _getPrefs();
      await prefs.remove('$_fallbackPrefix$key');
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

  /// Always wipe both backends. Skipping secure delete when [_preferFallback]
  /// is true left JWTs in the Windows credential/file store after logout.
  Future<void> _delete(String key) async {
    await _deleteSecureQuietly(key);
    final prefs = await _getPrefs();
    await prefs.remove('$_fallbackPrefix$key');
  }

  Future<void> _deleteSecureQuietly(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugPrint('AuthTokenStore: secure delete failed for $key: $e');
    }
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
    } else {
      await _delete(_expiresAtKey);
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
    // Key-level deletes for both backends.
    await Future.wait([
      _delete(_tokenKey),
      _delete(_userKey),
      _delete(_expiresAtKey),
    ]);

    // Belt-and-suspenders on Windows: wipe any remaining secure entries this
    // app may have written under other keys / backward-compat stores.
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('AuthTokenStore: secure deleteAll failed: $e');
    }

    // Wipe any leftover fallback keys (including unexpected ones).
    try {
      final prefs = await _getPrefs();
      final stale = prefs
          .getKeys()
          .where((k) => k.startsWith(_fallbackPrefix))
          .toList(growable: false);
      for (final key in stale) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('AuthTokenStore: fallback wipe failed: $e');
    }

    _preferFallback = false;

    // Verify — if a token still reads back, force another wipe.
    final leftover = await getToken();
    if (leftover != null && leftover.isNotEmpty) {
      debugPrint(
        'AuthTokenStore: token still present after clear; forcing wipe',
      );
      await _deleteSecureQuietly(_tokenKey);
      final prefs = await _getPrefs();
      await prefs.remove('$_fallbackPrefix$_tokenKey');
      try {
        await _storage.deleteAll();
      } catch (_) {}
    }
  }
}
