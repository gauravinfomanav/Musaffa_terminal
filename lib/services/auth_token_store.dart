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
///
/// On Windows, a corrupt `flutter_secure_storage.dat` or broken
/// SharedPreferences store used to throw [FormatException] during login even
/// after the API succeeded. This store recovers by retrying secure writes
/// (the Windows plugin deletes a corrupt DPAPI file then rethrows) and finally
/// keeping the session in memory when prefs are also unavailable.
class AuthTokenStore {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  static const _expiresAtKey = 'auth_expires_at';
  static const _fallbackPrefix = 'auth_fallback_';

  final FlutterSecureStorage _storage;
  SharedPreferences? _prefs;
  bool _preferFallback = false;
  bool _prefsBroken = false;
  final Map<String, String> _memory = <String, String>{};

  AuthTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              // Avoid legacy Windows credential-store merge paths that can
              // reintroduce corrupt/empty payloads into the DPAPI JSON file.
              wOptions: WindowsOptions(useBackwardCompatibility: false),
            );

  Future<SharedPreferences?> _getPrefs() async {
    if (_prefsBroken) return null;
    if (_prefs != null) return _prefs;

    try {
      return _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('AuthTokenStore: SharedPreferences unavailable: $e');
      // One more attempt — Windows sometimes recovers after the secure-store
      // plugin has already deleted a colliding corrupt file.
      try {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return _prefs = await SharedPreferences.getInstance();
      } catch (e2) {
        debugPrint('AuthTokenStore: SharedPreferences still broken: $e2');
        _prefsBroken = true;
        return null;
      }
    }
  }

  Future<void> _writeFallback(String key, String value) async {
    _memory[key] = value;
    final prefs = await _getPrefs();
    if (prefs == null) return;
    try {
      await prefs.setString('$_fallbackPrefix$key', value);
    } catch (e) {
      debugPrint('AuthTokenStore: fallback prefs write failed: $e');
      _prefsBroken = true;
    }
  }

  Future<void> _write(String key, String value) async {
    if (_preferFallback) {
      await _writeFallback(key, value);
      await _deleteSecureQuietly(key);
      return;
    }

    Future<void> secureWrite() => _storage.write(key: key, value: value);

    try {
      await secureWrite();
      // Successful secure write — drop any leftover fallback from an older
      // failure path so the two stores cannot disagree after logout.
      _memory.remove(key);
      final prefs = await _getPrefs();
      await prefs?.remove('$_fallbackPrefix$key');
      return;
    } catch (e, stack) {
      debugPrint('AuthTokenStore: secure write failed: $e');
      debugPrint('$stack');
      // Windows plugin deletes a corrupt DPAPI file then rethrows — retry once
      // on a clean slate before giving up on secure storage.
      try {
        await secureWrite();
        _memory.remove(key);
        final prefs = await _getPrefs();
        await prefs?.remove('$_fallbackPrefix$key');
        return;
      } catch (e2, stack2) {
        debugPrint(
          'AuthTokenStore: secure write retry failed, using fallback: $e2',
        );
        debugPrint('$stack2');
        _preferFallback = true;
        await _writeFallback(key, value);
      }
    }
  }

  Future<String?> _read(String key) async {
    if (_preferFallback) {
      final prefs = await _getPrefs();
      return prefs?.getString('$_fallbackPrefix$key') ?? _memory[key];
    }

    try {
      final value = await _storage.read(key: key);
      if (value != null) return value;
    } catch (e, stack) {
      debugPrint('AuthTokenStore: secure read failed, using fallback: $e');
      debugPrint('$stack');
      try {
        final value = await _storage.read(key: key);
        if (value != null) return value;
      } catch (_) {
        _preferFallback = true;
      }
    }

    if (_memory.containsKey(key)) return _memory[key];
    final prefs = await _getPrefs();
    return prefs?.getString('$_fallbackPrefix$key');
  }

  /// Always wipe both backends. Skipping secure delete when [_preferFallback]
  /// is true left JWTs in the Windows credential/file store after logout.
  Future<void> _delete(String key) async {
    _memory.remove(key);
    await _deleteSecureQuietly(key);
    final prefs = await _getPrefs();
    await prefs?.remove('$_fallbackPrefix$key');
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
    // Always keep an in-memory copy first so a later persistence failure cannot
    // leave AuthController without a usable session for this process.
    _memory[_tokenKey] = token;
    _memory[_userKey] = jsonEncode(user.toJson());
    if (expiresAt != null) {
      _memory[_expiresAtKey] = expiresAt;
    } else {
      _memory.remove(_expiresAtKey);
    }

    try {
      await _write(_tokenKey, token);
      await _write(_userKey, jsonEncode(user.toJson()));
      if (expiresAt != null) {
        await _write(_expiresAtKey, expiresAt);
      } else {
        await _delete(_expiresAtKey);
      }
    } catch (e, stack) {
      // Persistence is best-effort — memory already holds the session.
      debugPrint('AuthTokenStore: saveSession persistence failed: $e');
      debugPrint('$stack');
      _preferFallback = true;
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
    _memory.clear();

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
      if (prefs != null) {
        final stale = prefs
            .getKeys()
            .where((k) => k.startsWith(_fallbackPrefix))
            .toList(growable: false);
        for (final key in stale) {
          await prefs.remove(key);
        }
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
      _memory.remove(_tokenKey);
      await _deleteSecureQuietly(_tokenKey);
      final prefs = await _getPrefs();
      await prefs?.remove('$_fallbackPrefix$_tokenKey');
      try {
        await _storage.deleteAll();
      } catch (_) {}
    }
  }
}
