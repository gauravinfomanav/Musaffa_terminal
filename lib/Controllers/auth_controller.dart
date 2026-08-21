import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:musaffa_terminal/Screens/login_screen.dart';
import 'package:musaffa_terminal/Screens/main_screen.dart';
import 'package:musaffa_terminal/models/auth_models.dart';
import 'package:musaffa_terminal/services/auth_service.dart';
import 'package:musaffa_terminal/services/auth_token_store.dart';
import 'package:musaffa_terminal/Controllers/trading_ideas_controller.dart';
import 'package:musaffa_terminal/services/feature_access_service.dart';
import 'package:musaffa_terminal/services/global_watchlist_service.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/web_service.dart';

class AuthController extends GetxController {
  final AuthService _authService;
  final AuthTokenStore _tokenStore;

  AuthController({
    AuthService? authService,
    AuthTokenStore? tokenStore,
  })  : _authService = authService ?? AuthService(),
        _tokenStore = tokenStore ?? AuthTokenStore();

  final RxBool isInitializing = true.obs;
  final RxBool isLoading = false.obs;
  final RxBool isAuthenticated = false.obs;
  final Rxn<AuthUser> user = Rxn<AuthUser>();
  final RxnString errorMessage = RxnString();
  final RxnString successMessage = RxnString();

  bool _handlingUnauthorized = false;

  FeatureAccessService get _features {
    if (!Get.isRegistered<FeatureAccessService>()) {
      Get.put(FeatureAccessService(), permanent: true);
    }
    return Get.find<FeatureAccessService>();
  }

  @override
  void onInit() {
    super.onInit();
    WebService.tokenProvider = _tokenStore.getToken;
    WebService.onUnauthorized = handleUnauthorized;
    restoreSession();
  }

  @override
  void onClose() {
    if (identical(WebService.onUnauthorized, handleUnauthorized)) {
      WebService.onUnauthorized = null;
    }
    if (identical(WebService.tokenProvider, _tokenStore.getToken)) {
      WebService.tokenProvider = null;
    }
    super.onClose();
  }

  void clearMessages() {
    errorMessage.value = null;
    successMessage.value = null;
  }

  /// Clears user-scoped in-memory state so account switches don't leak data.
  void _clearUserScopedControllers() {
    if (Get.isRegistered<GlobalWatchlistService>()) {
      Get.find<GlobalWatchlistService>().closeWatchlist();
    }
    if (Get.isRegistered<WatchlistController>()) {
      Get.find<WatchlistController>().clearSessionData();
    }
    if (Get.isRegistered<TradingIdeasController>()) {
      Get.find<TradingIdeasController>().clearSessionData();
    }
    _features.reset();
  }

  Future<void> _syncFeatures({Map<String, dynamic>? seed}) async {
    if (seed != null) {
      _features.seedFromLogin(seed);
    }
    await _features.fetchFeatures();
  }

  Future<void> restoreSession() async {
    isInitializing.value = true;
    clearMessages();

    // Avoid mid-restore redirects from WebService 401 handling.
    final previousUnauthorized = WebService.onUnauthorized;
    WebService.onUnauthorized = null;

    try {
      final token = await _tokenStore.getToken();
      if (token == null || token.isEmpty) {
        isAuthenticated.value = false;
        user.value = null;
        _features.reset();
        return;
      }

      final cachedUser = await _tokenStore.getUser();
      if (cachedUser != null) {
        user.value = cachedUser;
        if (cachedUser.features != null) {
          _features.seedFromLogin(cachedUser.features);
        }
      }

      final me = await _authService.me();
      user.value = me;
      await _tokenStore.saveUser(me);
      isAuthenticated.value = true;
      await _syncFeatures(seed: me.features);
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        await _clearLocalSession();
      } else {
        // Offline / transient: keep cached token if present.
        final token = await _tokenStore.getToken();
        isAuthenticated.value = token != null && token.isNotEmpty;
        if (isAuthenticated.value) {
          await _features.fetchFeatures();
        }
      }
    } catch (_) {
      final token = await _tokenStore.getToken();
      isAuthenticated.value = token != null && token.isNotEmpty;
      if (isAuthenticated.value) {
        await _features.fetchFeatures();
      }
    } finally {
      WebService.onUnauthorized = previousUnauthorized ?? handleUnauthorized;
      isInitializing.value = false;
    }
  }

  Future<EmailCheckResult?> checkEmail(String email) async {
    isLoading.value = true;
    clearMessages();

    try {
      return await _authService.checkEmail(email);
    } on AuthException catch (e) {
      errorMessage.value = e.message;
      return null;
    } catch (_) {
      errorMessage.value = 'Something went wrong. Please try again.';
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    String? name,
  }) async {
    isLoading.value = true;
    clearMessages();

    try {
      final result = await _authService.register(
        email: email,
        password: password,
        name: name,
      );
      successMessage.value = result.message;
      return true;
    } on AuthException catch (e) {
      errorMessage.value = e.message;
      return false;
    } catch (_) {
      errorMessage.value = 'Something went wrong. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    clearMessages();

    try {
      final result = await _authService.login(
        email: email,
        password: password,
      );
      // Drop previous user's in-memory data before storing the new session.
      _clearUserScopedControllers();
      await _tokenStore.saveSession(
        token: result.token,
        user: result.user,
        expiresAt: result.expiresAt,
      );
      user.value = result.user;
      isAuthenticated.value = true;

      await _syncFeatures(seed: result.user.features);

      if (Get.isRegistered<WatchlistController>()) {
        // Force reload under the new Bearer token.
        await Get.find<WatchlistController>().reloadForCurrentUser();
      }

      Get.offAll(() => const MainScreen());
      return true;
    } on AuthException catch (e) {
      errorMessage.value = e.message;
      return false;
    } catch (e, stack) {
      debugPrint('AuthController.login failed after API success: $e');
      debugPrint('$stack');
      errorMessage.value = kDebugMode
          ? 'Login failed: $e'
          : 'Something went wrong. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    isLoading.value = true;
    clearMessages();

    // Capture the JWT, wipe local storage first, then revoke on the server.
    // On Windows a hung logout API (or a skipped secure-store delete) used to
    // leave the token on disk — a reload then restored the session.
    final token = await _tokenStore.getToken();

    try {
      _clearUserScopedControllers();
      await _clearLocalSession();
    } finally {
      isLoading.value = false;
      Get.offAll(() => const LoginScreen());
    }

    if (token != null && token.isNotEmpty) {
      // Fire-and-forget server revoke with the captured JWT.
      () async {
        try {
          await _authService
              .logout(bearerToken: token)
              .timeout(const Duration(seconds: 8));
        } catch (_) {}
      }();
    }
  }

  Future<void> handleUnauthorized() async {
    if (_handlingUnauthorized) return;
    _handlingUnauthorized = true;
    try {
      _clearUserScopedControllers();
      await _clearLocalSession();
      Get.offAll(() => const LoginScreen());
    } finally {
      _handlingUnauthorized = false;
    }
  }

  Future<void> _clearLocalSession() async {
    await _tokenStore.clear();
    user.value = null;
    isAuthenticated.value = false;
    _features.reset();
    clearMessages();
  }
}
