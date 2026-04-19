import 'package:flutter/material.dart';
import 'package:nagah/features/auth/presentation/widgets/auth_palette.dart';
import 'package:nagah/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:nagah/features/auth/presentation/widgets/auth_shell.dart';
import 'package:nagah/features/auth/presentation/widgets/auth_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.isLoading,
    required this.onLogin,
    required this.onOpenRegister,
    required this.onOpenForgotPassword,
  });

  final bool isLoading;
  final void Function({required String email, required String password})
  onLogin;
  final VoidCallback onOpenRegister;
  final VoidCallback onOpenForgotPassword;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController(
    text: 'demo.user@nagah.app',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: '123456',
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Login',
      subtitle:
          'Sign in to open reports, review road alerts, and continue to the safety map.',
      footer: Center(
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          children: [
            const Text(
              'New here?',
              style: TextStyle(color: AuthPalette.textMuted),
            ),
            TextButton(
              onPressed: widget.onOpenRegister,
              child: const Text('Create account'),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MockHint(),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'name@example.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline_rounded,
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: _passwordController,
            label: 'Password',
            obscureText: true,
            prefixIcon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.onOpenForgotPassword,
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 8),
          AuthPrimaryButton(
            label: 'Login',
            icon: Icons.login_rounded,
            isLoading: widget.isLoading,
            onPressed: () {
              widget.onLogin(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MockHint extends StatelessWidget {
  const _MockHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AuthPalette.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'Mock mode: use any valid email and a password with at least 6 characters. Admin login: admin@nagah.app / Admin@123',
        style: TextStyle(color: AuthPalette.textPrimary, height: 1.4),
      ),
    );
  }
}
