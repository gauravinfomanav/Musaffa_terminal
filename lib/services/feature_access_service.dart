import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/auth_controller.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/web_service.dart';
import 'package:musaffa_terminal/services/global_watchlist_service.dart';

/// Holds the per-user feature map from `GET /auth/features`.
class FeatureAccessService extends GetxController with WidgetsBindingObserver {
  final RxMap<String, bool> features = <String, bool>{}.obs;
  final RxBool isLoaded = false.obs;
  final RxBool isRefreshing = false.obs;

  bool _handlingFeatureDisabled = false;
  DateTime? _lastFetchAt;
  static const Duration _minFetchInterval = Duration(seconds: 30);

  static Map<String, bool> defaultAllTrue() => {
        for (final key in FeatureKeys.all) key: true,
      };

  @override
  void onInit() {
    super.onInit();
    features.assignAll(defaultAllTrue());
    WidgetsBinding.instance.addObserver(this);
    WebService.onFeatureDisabled = _handleFeatureDisabled;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    if (identical(WebService.onFeatureDisabled, _handleFeatureDisabled)) {
      WebService.onFeatureDisabled = null;
    }
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!Get.isRegistered<AuthController>()) return;
    if (!Get.find<AuthController>().isAuthenticated.value) return;
    fetchFeatures();
  }

  bool isEnabled(String key) => features[key] != false;

  void applyFromServer(Map<String, dynamic>? raw) {
    final next = defaultAllTrue();
    if (raw != null) {
      for (final key in FeatureKeys.all) {
        if (raw.containsKey(key)) {
          next[key] = raw[key] == true;
        }
      }
    }
    features.assignAll(next);
    isLoaded.value = true;

    // Close watchlist panel if access was revoked while open.
    if (next[FeatureKeys.watchlists] != true &&
        Get.isRegistered<GlobalWatchlistService>()) {
      Get.find<GlobalWatchlistService>().closeWatchlist();
    }
  }

  void seedFromLogin(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return;
    applyFromServer(raw);
  }

  void reset() {
    features.assignAll(defaultAllTrue());
    isLoaded.value = false;
  }

  /// Dedicated source of truth: `GET /auth/features` → `data.features`.
  Future<bool> fetchFeatures({bool force = false}) async {
    if (isRefreshing.value) return isLoaded.value;
    if (!force &&
        _lastFetchAt != null &&
        DateTime.now().difference(_lastFetchAt!) < _minFetchInterval) {
      return isLoaded.value;
    }
    isRefreshing.value = true;

    try {
      final response = await WebService.callApi(
        method: HttpMethod.GET,
        path: ['auth', 'features'],
        attachAuthToken: true,
      );

      if (response.status == ApiStatus.SUCCESS && response.data != null) {
        final json = jsonDecode(response.data!) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>? ?? {};
        final map = data['features'];
        if (map is Map<String, dynamic>) {
          applyFromServer(map);
          return true;
        }
        if (map is Map) {
          applyFromServer(Map<String, dynamic>.from(map));
          return true;
        }
      }

      // Fail open: keep defaults / last known map.
      if (!isLoaded.value) {
        applyFromServer(null);
      }
      return false;
    } catch (_) {
      if (!isLoaded.value) {
        applyFromServer(null);
      }
      return false;
    } finally {
      _lastFetchAt = DateTime.now();
      isRefreshing.value = false;
    }
  }

  Future<void> _handleFeatureDisabled(String feature, String message) async {
    if (_handlingFeatureDisabled) return;
    _handlingFeatureDisabled = true;
    try {
      if (FeatureKeys.all.contains(feature)) {
        features[feature] = false;
      }

      final label = FeatureKeys.displayName(feature);
      Get.snackbar(
        'Feature unavailable',
        message.isNotEmpty
            ? message
            : '$label isn’t available for your account.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      if (Get.key.currentState?.canPop() == true) {
        Get.back();
      }
    } finally {
      _handlingFeatureDisabled = false;
    }
  }
}
