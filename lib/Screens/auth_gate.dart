import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/auth_controller.dart';
import 'package:musaffa_terminal/Screens/login_screen.dart';
import 'package:musaffa_terminal/Screens/main_screen.dart';
import 'package:musaffa_terminal/Screens/splash_screen.dart';

/// Resolves session on launch with a premium zoom-in splash, then login or home.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _splashFinished = false;

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    if (!_splashFinished) {
      return Obx(
        () => PremiumLaunchSplash(
          isWaiting: auth.isInitializing.value,
          onFinished: () {
            if (!mounted) return;
            setState(() => _splashFinished = true);
          },
        ),
      );
    }

    return Obx(() {
      if (auth.isAuthenticated.value) {
        return const MainScreen();
      }
      return const LoginScreen();
    });
  }
}
