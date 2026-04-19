import 'package:flutter/material.dart';
import 'package:nagah/features/auth/presentation/widgets/auth_palette.dart';
import 'package:nagah/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:nagah/features/auth/presentation/widgets/auth_shell.dart';
import 'package:nagah/features/auth/presentation/widgets/auth_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.isLoading,
    required this.onRegister,
    required this.onOpenLogin,
  });

  final bool isLoading;
  final void Function({
    required String name,
    required String email,
    required String phone,
    required String password,
  })
  onRegister;
  final VoidCallback onOpenLogin;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Register',
      subtitle:
          'Create a new driver account to report accidents, traffic, and road damage.',
      footer: Center(
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          children: [
            const Text(
              'Already have an account?',
              style: TextStyle(color: AuthPalette.textMuted),
            ),
            TextButton(
              onPressed: widget.onOpenLogin,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          AuthTextField(
            controller: _nameController,
            label: 'Full name',
            prefixIcon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: _emailController,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline_rounded,
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: _phoneController,
            label: 'Phone number',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: _passwordController,
            label: 'Password',
            obscureText: true,
            prefixIcon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 18),
          AuthPrimaryButton(
            label: 'Create account',
            icon: Icons.person_add_alt_1_rounded,
            isLoading: widget.isLoading,
            onPressed: () {
              widget.onRegister(
                name: _nameController.text.trim(),
                email: _emailController.text.trim(),
                phone: _phoneController.text.trim(),
                password: _passwordController.text.trim(),
              );
            },
          ),
        ],
      ),
    );
  }
}
