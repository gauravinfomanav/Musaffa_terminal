import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/feature_blocked_page.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/services/feature_access_service.dart';

class FeatureNavigation {
  FeatureNavigation._();

  static FeatureAccessService get _features {
    if (!Get.isRegistered<FeatureAccessService>()) {
      Get.put(FeatureAccessService(), permanent: true);
    }
    return Get.find<FeatureAccessService>();
  }

  static bool isEnabled(String key) => _features.isEnabled(key);

  /// Navigate with GetX if allowed; otherwise show blocked page.
  static Future<T?>? toIfAllowed<T>(
    String featureKey,
    Widget Function() page, {
    String? featureName,
    Transition? transition,
    bool? fullscreenDialog,
    String? routeName,
  }) {
    if (!isEnabled(featureKey)) {
      return Get.to<T>(
        () => FeatureBlockedPage(
          featureKey: featureKey,
          featureName: featureName ?? FeatureKeys.displayName(featureKey),
        ),
        transition: Transition.fadeIn,
      );
    }
    return Get.to<T>(
      page,
      transition: transition,
      fullscreenDialog: fullscreenDialog ?? false,
      routeName: routeName,
    );
  }

  /// Navigator.push if allowed; otherwise show blocked page.
  static Future<T?> pushIfAllowed<T extends Object?>(
    BuildContext context,
    String featureKey,
    Widget page, {
    String? featureName,
  }) {
    final target = isEnabled(featureKey)
        ? page
        : FeatureBlockedPage(
            featureKey: featureKey,
            featureName: featureName ?? FeatureKeys.displayName(featureKey),
          );
    return Navigator.of(context).push<T>(
      MaterialPageRoute(builder: (_) => target),
    );
  }
}

/// Reactive guard for screens already opened (deep link / stale route).
class FeatureGuard extends StatelessWidget {
  const FeatureGuard({
    super.key,
    required this.featureKey,
    required this.child,
    this.featureName,
  });

  final String featureKey;
  final String? featureName;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<FeatureAccessService>()) {
      return child;
    }
    return Obx(() {
      final enabled =
          Get.find<FeatureAccessService>().isEnabled(featureKey);
      if (!enabled) {
        return FeatureBlockedPage(
          featureKey: featureKey,
          featureName: featureName ?? FeatureKeys.displayName(featureKey),
        );
      }
      return child;
    });
  }
}
