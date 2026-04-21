import 'package:flutter/material.dart';
import 'package:nagah/features/auth/domain/model/auth_models.dart';
import 'package:nagah/features/auth/presentation/widgets/auth_palette.dart';
import 'package:nagah/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:nagah/features/auth/presentation/widgets/auth_shell.dart';
import 'package:nagah/features/auth/presentation/widgets/auth_text_field.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.isLoading,
    required this.session,
    required this.onVerify,
    required this.onResend,
    required this.onBack,
  });

  final bool isLoading;
  final OtpSession session;
  final void Function({required String code}) onVerify;
  final VoidCallback onResend;
  final VoidCallback onBack;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purposeLabel = widget.session.purpose == OtpPurpose.register
        ? 'account verification'
        : 'password reset';

    return AuthShell(
      title: 'OTP Verification',
      subtitle: 'Enter the code we sent for $purposeLabel.',
      footer: Center(
        child: TextButton(
          onPressed: widget.onBack,
          child: const Text('Back'),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AuthPalette.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verification destination',
                  style: TextStyle(
                    color: AuthPalette.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.session.email,
                  style: const TextStyle(
                    color: AuthPalette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _otpController,
            label: 'OTP code',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.password_rounded,
          ),
          const SizedBox(height: 18),
          AuthPrimaryButton(
            label: 'Verify code',
            icon: Icons.verified_user_rounded,
            isLoading: widget.isLoading,
            onPressed: () {
              widget.onVerify(code: _otpController.text.trim());
            },
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.isLoading ? null : widget.onResend,
              child: const Text('Resend OTP'),
            ),
          ),
        ],
      ),
    );
  }
}
