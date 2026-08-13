import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/services/feature_access_service.dart';
import 'package:musaffa_terminal/utils/constants.dart';

/// Calm blocked state when a disabled feature is opened via deep link / old route.
class FeatureBlockedPage extends StatelessWidget {
  const FeatureBlockedPage({
    super.key,
    required this.featureKey,
    this.featureName,
  });

  final String featureKey;
  final String? featureName;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA);
    final card = isDark ? const Color(0xFF151718) : Colors.white;
    final border = isDark ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB);
    final title = isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111827);
    final muted = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final name = featureName ?? FeatureKeys.displayName(featureKey);

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.lock_fill, size: 28, color: muted),
                const SizedBox(height: 14),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: title,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This feature isn’t available for your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 13,
                    height: 1.4,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Contact your admin if you need access.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 12,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else if (Get.key.currentState?.canPop() == true) {
                      Get.back();
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: isDark
                        ? const Color(0xFF81AACE)
                        : const Color(0xFF2563EB),
                    textStyle: const TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
