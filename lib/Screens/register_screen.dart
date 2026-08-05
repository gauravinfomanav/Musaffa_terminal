import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/auth_controller.dart';
import 'package:musaffa_terminal/Screens/login_screen.dart';
import 'package:musaffa_terminal/models/auth_models.dart';
import 'package:musaffa_terminal/utils/constants.dart';

/// Email-first registration: check-email → set password → go to Login.
class RegisterScreen extends StatefulWidget {
  final String? initialEmail;

  const RegisterScreen({Key? key, this.initialEmail}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  EmailCheckResult? _emailCheck;
  String? _checkedEmail;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
    _emailController.addListener(_onEmailChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<AuthController>()) {
        Get.find<AuthController>().clearMessages();
      }
    });
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    final current = _emailController.text.trim();
    if (_emailCheck == null) return;
    if (current == _checkedEmail) return;

    setState(() {
      _emailCheck = null;
      _checkedEmail = null;
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
    if (Get.isRegistered<AuthController>()) {
      Get.find<AuthController>().clearMessages();
    }
  }

  bool get _showPasswordStep =>
      _emailCheck != null &&
      _emailCheck!.canEnterPassword &&
      !_emailCheck!.registered;

  String get _primaryButtonLabel =>
      _showPasswordStep ? 'Create password' : 'Continue';

  String get _subtitle {
    if (_showPasswordStep) {
      if (_emailCheck?.domainAllowed == true) {
        return 'Company email verified — create a password';
      }
      return 'Create a password for your Terminal account';
    }
    return 'Enter your email to continue registration';
  }

  String _nameFromEmail(String email) {
    final local = email.trim().split('@').first;
    return local.isNotEmpty ? local : email.trim();
  }

  Future<void> _onPrimaryAction() async {
    FocusScope.of(context).unfocus();
    final auth = Get.find<AuthController>();

    if (!_showPasswordStep) {
      final email = _emailController.text.trim();
      if (email.isEmpty || !email.contains('@')) {
        _formKey.currentState?.validate();
        return;
      }

      final result = await auth.checkEmail(email);
      if (!mounted || result == null) return;

      setState(() {
        _emailCheck = result;
        _checkedEmail = email;
        _passwordController.clear();
        _confirmPasswordController.clear();
      });

      if (result.exists && result.registered && result.isActive) {
        auth.successMessage.value =
            'Account already registered. Please login.';
        return;
      }

      if (result.canEnterPassword && !result.registered) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _passwordFocus.requestFocus();
        });
      }
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final ok = await auth.register(
      email: _emailController.text,
      password: _passwordController.text,
      name: _nameFromEmail(_emailController.text),
    );
    if (!mounted || !ok) return;

    Get.off(
      () => LoginScreen(initialEmail: _emailController.text.trim()),
    );
  }

  void _goToLogin() {
    final auth = Get.find<AuthController>();
    auth.clearMessages();
    Get.off(
      () => LoginScreen(initialEmail: _emailController.text.trim()),
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

    final subtitle = _subtitle;

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
                            child: SvgPicture.asset(
                              'resources/Small Logo.svg',
                              height: 28,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Register',
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
                            subtitle,
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
                              textInputAction: _showPasswordStep
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              autofillHints: const [AutofillHints.email],
                              onFieldSubmitted: (_) => _onPrimaryAction(),
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
                          if (_emailCheck != null && !_emailCheck!.exists) ...[
                            const SizedBox(height: 14),
                            const _InfoBanner(
                              message: 'No account found. Contact admin.',
                              isError: true,
                            ),
                          ],
                          if (_emailCheck != null &&
                              _emailCheck!.exists &&
                              !_emailCheck!.isActive) ...[
                            const SizedBox(height: 14),
                            const _InfoBanner(
                              message: 'Account is not active',
                              isError: true,
                            ),
                          ],
                          if (_emailCheck != null &&
                              _emailCheck!.exists &&
                              _emailCheck!.registered &&
                              _emailCheck!.isActive) ...[
                            const SizedBox(height: 14),
                            const _InfoBanner(
                              message:
                                  'Account already registered. Please login.',
                              isError: false,
                            ),
                          ],
                          if (_showPasswordStep) ...[
                            const SizedBox(height: 16),
                            _LabeledField(
                              label: 'Password',
                              mutedColor: mutedColor,
                              child: TextFormField(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.newPassword
                                ],
                                onFieldSubmitted: (_) =>
                                    _confirmFocus.requestFocus(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: titleColor,
                                  fontFamily: Constants.FONT_DEFAULT_NEW,
                                ),
                                decoration: _inputDecoration(
                                  hint: 'Min. 6 characters',
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
                                  if (!_showPasswordStep) return null;
                                  if (value == null || value.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            _LabeledField(
                              label: 'Confirm password',
                              mutedColor: mutedColor,
                              child: TextFormField(
                                controller: _confirmPasswordController,
                                focusNode: _confirmFocus,
                                obscureText: _obscureConfirm,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _onPrimaryAction(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: titleColor,
                                  fontFamily: Constants.FONT_DEFAULT_NEW,
                                ),
                                decoration: _inputDecoration(
                                  hint: 'Re-enter your password',
                                  isDarkMode: isDarkMode,
                                  accent: accent,
                                  borderColor: borderColor,
                                  prefixIcon: Icons.lock_outline_rounded,
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirm = !_obscureConfirm;
                                      });
                                    },
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 18,
                                      color: mutedColor,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (!_showPasswordStep) return null;
                                  if (value == null || value.isEmpty) {
                                    return 'Confirm your password';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
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
                            final alreadyRegistered = _emailCheck != null &&
                                _emailCheck!.exists &&
                                _emailCheck!.registered &&
                                _emailCheck!.isActive;

                            return SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                onPressed: loading
                                    ? null
                                    : (alreadyRegistered
                                        ? _goToLogin
                                        : _onPrimaryAction),
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
                                    : Text(
                                        alreadyRegistered
                                            ? 'Go to Login'
                                            : _primaryButtonLabel,
                                        style: const TextStyle(
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
                                'Already registered? ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: mutedColor,
                                  fontFamily: Constants.FONT_DEFAULT_NEW,
                                ),
                              ),
                              GestureDetector(
                                onTap: _goToLogin,
                                child: Text(
                                  'Login',
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
                            _emailCheck?.domainAllowed == true
                                ? 'Allowed company emails can self-register'
                                : 'Your email must be created by an administrator first',
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
