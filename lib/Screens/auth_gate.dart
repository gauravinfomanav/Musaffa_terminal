import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:musaffa_terminal/Controllers/auth_controller.dart';
import 'package:musaffa_terminal/Screens/login_screen.dart';
import 'package:musaffa_terminal/Screens/main_screen.dart';

/// Resolves session on launch: loading → login or home.
class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (auth.isInitializing.value) {
        return Scaffold(
          backgroundColor:
              isDarkMode ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA),
          body: Center(
            child: Lottie.asset(
              'resources/Sandy Loading.json',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
              repeat: true,
            ),
          ),
        );
      }

      if (auth.isAuthenticated.value) {
        return const MainScreen();
      }

      return const LoginScreen();
    });
  }
}
