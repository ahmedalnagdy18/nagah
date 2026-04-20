import 'package:flutter/material.dart';
import 'package:nagah/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:nagah/features/auth/presentation/widgets/auth_shell.dart';
import 'package:nagah/features/auth/presentation/widgets/auth_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    required this.isLoading,
    required this.onSendOtp,
    required this.onBackToLogin,
  });

  final bool isLoading;
  final void Function({required String email}) onSendOtp;
  final VoidCallback onBackToLogin;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Forgot Password',
      subtitle:
          'Enter your email address and we will send an OTP verification code.',
      footer: Center(
        child: TextButton(
          onPressed: widget.onBackToLogin,
          child: const Text('Back to login'),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthTextField(
            controller: _emailController,
            label: 'Email address',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline_rounded,
          ),
          const SizedBox(height: 18),
          AuthPrimaryButton(
            label: 'Send OTP',
            icon: Icons.send_to_mobile_rounded,
            isLoading: widget.isLoading,
            onPressed: () {
              widget.onSendOtp(email: _emailController.text.trim());
            },
          ),
        ],
      ),
    );
  }
}
