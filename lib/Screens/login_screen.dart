import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/auth_page_shell.dart';
import 'package:musaffa_terminal/Controllers/auth_controller.dart';
import 'package:musaffa_terminal/Screens/register_screen.dart';
import 'package:musaffa_terminal/utils/constants.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = AuthPalette.of(isDark);
    final titleStyle = TextStyle(
      fontSize: 13.5,
      color: palette.title,
      fontFamily: Constants.FONT_DEFAULT_NEW,
    );

    return AuthPageShell(
      title: 'Welcome back',
      subtitle: 'Sign in to Musaffa Terminal',
      footnote: 'Use your Terminal account credentials',
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
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
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
            const SizedBox(height: 16),
            AuthLabeledField(
              label: 'Password',
              child: TextFormField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _submit(),
                style: titleStyle,
                decoration: authInputDecoration(
                  hint: 'Enter your password',
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
                child: AuthInfoBanner(message: success, isError: false),
              );
            }),
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
                label: 'Sign in',
                loading: loading,
                onPressed: loading ? null : _submit,
              );
            }),
          ],
        ),
      ),
      footer: AuthTextLink(
        prefix: "Don't have a password yet? ",
        linkLabel: 'Register',
        onTap: () {
          auth.clearMessages();
          Get.to(
            () => RegisterScreen(
              initialEmail: _emailController.text.trim(),
            ),
          );
        },
      ),
    );
  }
}
