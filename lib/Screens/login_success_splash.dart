import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/auth_controller.dart';
import 'package:musaffa_terminal/Screens/login_screen.dart';
import 'package:musaffa_terminal/Screens/main_screen.dart';
import 'package:musaffa_terminal/Screens/splash_screen.dart';

/// Premium splash shown after sign-in — replaces the button loader.
class LoginSuccessSplash extends StatefulWidget {
  const LoginSuccessSplash({
    super.key,
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  State<LoginSuccessSplash> createState() => _LoginSuccessSplashState();
}

class _LoginSuccessSplashState extends State<LoginSuccessSplash> {
  bool _loginComplete = false;

  @override
  void initState() {
    super.initState();
    _runLogin();
  }

  Future<void> _runLogin() async {
    final auth = Get.find<AuthController>();
    final ok = await auth.login(
      email: widget.email,
      password: widget.password,
    );
    if (!mounted) return;

    if (!ok) {
      Get.offAll(
        () => LoginScreen(initialEmail: widget.email),
      );
      return;
    }

    setState(() => _loginComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    return PremiumLaunchSplash(
      isWaiting: !_loginComplete,
      onFinished: () => Get.offAll(() => const MainScreen()),
    );
  }
}
