import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/auth_controller.dart';
import 'package:musaffa_terminal/Screens/register_screen.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/utils.dart';

class LoginScreen extends StatefulWidget {
  final String? initialEmail;

  const LoginScreen({Key? key, this.initialEmail}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = Get.find<AuthController>();
    await auth.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 720;

    final bgTop = isDarkMode ? const Color(0xFF0B1220) : const Color(0xFFF3F7FB);
    final bgBottom = isDarkMode ? const Color(0xFF111827) : const Color(0xFFE8EEF5);
    final cardColor = isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor =
        isDarkMode ? const Color(0xFF2F3747) : const Color(0xFFE5E7EB);
    final titleColor =
        isDarkMode ? const Color(0xFFF3F4F6) : const Color(0xFF111827);
    final mutedColor =
        isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final accent = isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF2563EB);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -60,
              child: _GlowBlob(
                color: accent.withOpacity(isDarkMode ? 0.18 : 0.12),
                size: 260,
              ),
            ),
            Positioned(
              bottom: -100,
              left: -40,
              child: _GlowBlob(
                color: (isDarkMode ? const Color(0xFF34D399) : const Color(0xFF60A5FA))
                    .withOpacity(0.10),
                size: 280,
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 20 : 32,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 22 : 32,
                      vertical: isCompact ? 28 : 36,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDarkMode ? 0.35 : 0.08),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: const MusaffaLogo(height: 28),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Welcome back',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: titleColor,
                              fontFamily: Constants.FONT_DEFAULT_NEW,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sign in to Musaffa Terminal',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: mutedColor,
                              fontFamily: Constants.FONT_DEFAULT_NEW,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _LabeledField(
                            label: 'Email',
                            mutedColor: mutedColor,
                            child: TextFormField(
                              controller: _emailController,
                              focusNode: _emailFocus,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              onFieldSubmitted: (_) =>
                                  _passwordFocus.requestFocus(),
                              style: TextStyle(
                                fontSize: 13,
                                color: titleColor,
                                fontFamily: Constants.FONT_DEFAULT_NEW,
                              ),
                              decoration: _inputDecoration(
                                hint: 'you@company.com',
                                isDarkMode: isDarkMode,
                                accent: accent,
                                borderColor: borderColor,
                                prefixIcon: Icons.mail_outline_rounded,
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (email.isEmpty) return 'Email is required';
                                if (!email.contains('@')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _LabeledField(
                            label: 'Password',
                            mutedColor: mutedColor,
                            child: TextFormField(
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted: (_) => _submit(),
                              style: TextStyle(
                                fontSize: 13,
                                color: titleColor,
                                fontFamily: Constants.FONT_DEFAULT_NEW,
                              ),
                              decoration: _inputDecoration(
                                hint: 'Enter your password',
                                isDarkMode: isDarkMode,
                                accent: accent,
                                borderColor: borderColor,
                                prefixIcon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 18,
                                    color: mutedColor,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          Obx(() {
                            final success = auth.successMessage.value;
                            if (success == null || success.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: _InfoBanner(
                                message: success,
                                isError: false,
                              ),
                            );
                          }),
                          Obx(() {
                            final error = auth.errorMessage.value;
                            if (error == null || error.isEmpty) {
                              return const SizedBox(height: 20);
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 14, bottom: 8),
                              child: _InfoBanner(
                                message: error,
                                isError: true,
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          Obx(() {
                            final loading = auth.isLoading.value;
                            return SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                onPressed: loading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent,
                                  disabledBackgroundColor:
                                      accent.withOpacity(0.55),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Text(
                                        'Sign in',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: Constants.FONT_DEFAULT_NEW,
                                        ),
                                      ),
                              ),
                            );
                          }),
                          const SizedBox(height: 18),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                "Don't have a password yet? ",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: mutedColor,
                                  fontFamily: Constants.FONT_DEFAULT_NEW,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  auth.clearMessages();
                                  Get.to(
                                    () => RegisterScreen(
                                      initialEmail: _emailController.text.trim(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Register',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: accent,
                                    fontFamily: Constants.FONT_DEFAULT_NEW,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Use your Terminal account credentials',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: mutedColor,
                              fontFamily: Constants.FONT_DEFAULT_NEW,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required bool isDarkMode,
    required Color accent,
    required Color borderColor,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    final fill =
        isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 13,
        color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
        fontFamily: Constants.FONT_DEFAULT_NEW,
      ),
      filled: true,
      fillColor: fill,
      prefixIcon: Icon(prefixIcon, size: 18, color: accent),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: accent, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const _InfoBanner({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final bg = isError ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5);
    final border = isError ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0);
    final iconColor =
        isError ? const Color(0xFFDC2626) : const Color(0xFF059669);
    final textColor =
        isError ? const Color(0xFFB91C1C) : const Color(0xFF047857);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Color mutedColor;
  final Widget child;

  const _LabeledField({
    required this.label,
    required this.mutedColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: mutedColor,
            fontFamily: Constants.FONT_DEFAULT_NEW,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
