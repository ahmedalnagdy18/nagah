import 'package:flutter/material.dart';
import 'package:nagah/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:nagah/features/auth/presentation/widgets/auth_shell.dart';
import 'package:nagah/features/auth/presentation/widgets/auth_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.isLoading,
    required this.onResetPassword,
  });

  final bool isLoading;
  final void Function({
    required String password,
    required String confirmPassword,
  })
  onResetPassword;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Reset Password',
      subtitle: 'Choose a new password after the OTP verification step.',
      child: Column(
        children: [
          AuthTextField(
            controller: _passwordController,
            label: 'New password',
            obscureText: true,
            prefixIcon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: _confirmPasswordController,
            label: 'Confirm password',
            obscureText: true,
            prefixIcon: Icons.lock_reset_rounded,
          ),
          const SizedBox(height: 18),
          AuthPrimaryButton(
            label: 'Save new password',
            icon: Icons.check_circle_outline_rounded,
            isLoading: widget.isLoading,
            onPressed: () {
              widget.onResetPassword(
                password: _passwordController.text.trim(),
                confirmPassword: _confirmPasswordController.text.trim(),
              );
            },
          ),
        ],
      ),
    );
  }
}
