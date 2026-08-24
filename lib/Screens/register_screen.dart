import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/auth_page_shell.dart';
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
      return 'Create a password for your ${Constants.appName} account';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = AuthPalette.of(isDark);
    final titleStyle = TextStyle(
      fontSize: 13.5,
      color: palette.title,
      fontFamily: Constants.FONT_DEFAULT_NEW,
    );

    final alreadyRegistered = _emailCheck != null &&
        _emailCheck!.exists &&
        _emailCheck!.registered &&
        _emailCheck!.isActive;

    return AuthPageShell(
      title: 'Create account',
      subtitle: _subtitle,
      footnote: _emailCheck?.domainAllowed == true
          ? 'Allowed company emails can self-register'
          : 'Your email must be created by an administrator first',
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthLabeledField(
              label: 'Email',
              child: TextFormField(
                controller: _emailController,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                textInputAction: _showPasswordStep
                    ? TextInputAction.next
                    : TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                onFieldSubmitted: (_) => _onPrimaryAction(),
                style: titleStyle,
                decoration: authInputDecoration(
                  hint: 'you@company.com',
                  palette: palette,
                  prefixIcon: Icons.mail_outline_rounded,
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'Email is required';
                  if (!email.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
            ),
            if (_emailCheck != null && !_emailCheck!.exists) ...[
              const SizedBox(height: 14),
              const AuthInfoBanner(
                message: 'No account found. Contact admin.',
                isError: true,
              ),
            ],
            if (_emailCheck != null &&
                _emailCheck!.exists &&
                !_emailCheck!.isActive) ...[
              const SizedBox(height: 14),
              const AuthInfoBanner(
                message: 'Account is not active',
                isError: true,
              ),
            ],
            if (alreadyRegistered) ...[
              const SizedBox(height: 14),
              const AuthInfoBanner(
                message: 'Account already registered. Please login.',
                isError: false,
              ),
            ],
            if (_showPasswordStep) ...[
              const SizedBox(height: 16),
              AuthLabeledField(
                label: 'Password',
                child: TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
                  style: titleStyle,
                  decoration: authInputDecoration(
                    hint: 'Min. 6 characters',
                    palette: palette,
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: palette.muted,
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
              AuthLabeledField(
                label: 'Confirm password',
                child: TextFormField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmFocus,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _onPrimaryAction(),
                  style: titleStyle,
                  decoration: authInputDecoration(
                    hint: 'Re-enter your password',
                    palette: palette,
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: palette.muted,
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
                return const SizedBox(height: 22);
              }
              return Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 10),
                child: AuthInfoBanner(message: error, isError: true),
              );
            }),
            Obx(() {
              final loading = auth.isLoading.value;
              return AuthPrimaryButton(
                label: alreadyRegistered ? 'Go to Login' : _primaryButtonLabel,
                loading: loading,
                onPressed: loading
                    ? null
                    : (alreadyRegistered ? _goToLogin : _onPrimaryAction),
              );
            }),
          ],
        ),
      ),
      footer: AuthTextLink(
        prefix: 'Already registered? ',
        linkLabel: 'Login',
        onTap: _goToLogin,
      ),
    );
  }
}
