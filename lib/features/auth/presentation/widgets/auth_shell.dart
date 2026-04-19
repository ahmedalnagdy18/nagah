import 'package:flutter/material.dart';
import 'package:nagah/features/auth/presentation/widgets/auth_palette.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthPalette.background,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF161616), Color(0xFFF97316)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NAGAH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Secure access for drivers and admins before entering the road safety system.',
                      style: TextStyle(color: Color(0xFFFFEDD5), height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                style: const TextStyle(
                  color: AuthPalette.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AuthPalette.textMuted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AuthPalette.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AuthPalette.border),
                ),
                child: child,
              ),
              if (footer != null) ...[
                const SizedBox(height: 18),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
