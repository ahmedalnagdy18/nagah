import 'package:flutter/material.dart';
import 'package:nagah/features/auth/presentation/widgets/auth_palette.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: AuthPalette.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AuthPalette.textMuted),
        hintStyle: const TextStyle(color: AuthPalette.textMuted),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: AuthPalette.primary),
        filled: true,
        fillColor: AuthPalette.cardSecondary,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AuthPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AuthPalette.primary),
        ),
      ),
    );
  }
}
