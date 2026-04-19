import 'dart:async';

import 'package:nagah/features/auth/data/model/auth_models.dart';
import 'package:nagah/features/auth/domain/model/auth_models.dart';

class AuthLocalDataSource {
  static const String adminEmail = 'admin@nagah.app';
  static const String adminPassword = 'Admin@123';

  Future<AuthUserModel> login(LoginParams params) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    _validateEmail(params.email);
    _validatePassword(params.password);

    if (params.email.trim().toLowerCase() == adminEmail &&
        params.password == adminPassword) {
      return const AuthUserModel(
        id: 'admin-1',
        name: 'Nagah Admin',
        email: adminEmail,
        role: UserRole.admin,
      );
    }

    return AuthUserModel(
      id: 'user-1',
      name: 'Nagah Driver',
      email: params.email,
      role: UserRole.user,
    );
  }

  Future<OtpSessionModel> register(RegisterParams params) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (params.name.trim().length < 3) {
      throw Exception('Name must be at least 3 characters.');
    }
    _validateEmail(params.email);
    if (params.phone.trim().length < 11) {
      throw Exception('Phone number looks too short.');
    }
    _validatePassword(params.password);

    return const OtpSessionModel(
      sessionId: 'register-session',
      email: 'new.user@nagah.app',
      purpose: OtpPurpose.register,
      hintCode: '1234',
    );
  }

  Future<OtpSessionModel> requestPasswordReset(
    ForgotPasswordParams params,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    _validateEmail(params.email);

    return OtpSessionModel(
      sessionId: 'reset-session',
      email: params.email,
      purpose: OtpPurpose.resetPassword,
      hintCode: '1234',
    );
  }

  Future<OtpSessionModel> verifyOtp(VerifyOtpParams params) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (params.code.trim() != '1234') {
      throw Exception('Invalid OTP code. Try 1234 in the mock flow.');
    }

    if (params.sessionId == 'register-session') {
      return const OtpSessionModel(
        sessionId: 'register-verified',
        email: 'new.user@nagah.app',
        purpose: OtpPurpose.register,
        hintCode: '1234',
      );
    }

    return const OtpSessionModel(
      sessionId: 'reset-verified',
      email: 'demo.user@nagah.app',
      purpose: OtpPurpose.resetPassword,
      hintCode: '1234',
    );
  }

  Future<AuthUserModel> resetPassword(ResetPasswordParams params) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (params.sessionId != 'reset-verified') {
      throw Exception(
        'OTP verification is required before resetting password.',
      );
    }

    _validatePassword(params.password);

    if (params.password != params.confirmPassword) {
      throw Exception('Passwords do not match.');
    }

    return const AuthUserModel(
      id: 'user-1',
      name: 'Nagah Driver',
      email: 'demo.user@nagah.app',
      role: UserRole.user,
    );
  }

  void _validateEmail(String email) {
    if (!email.contains('@') || !email.contains('.')) {
      throw Exception('Please enter a valid email address.');
    }
  }

  void _validatePassword(String password) {
    if (password.trim().length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }
  }
}
