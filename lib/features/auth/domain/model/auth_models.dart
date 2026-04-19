enum UserRole { user, admin }

enum AuthStage {
  login,
  register,
  forgotPassword,
  otp,
  resetPassword,
}

enum OtpPurpose { register, resetPassword }

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
}

class OtpSession {
  const OtpSession({
    required this.sessionId,
    required this.email,
    required this.purpose,
    required this.hintCode,
  });

  final String sessionId;
  final String email;
  final OtpPurpose purpose;
  final String hintCode;
}

class LoginParams {
  const LoginParams({required this.email, required this.password});

  final String email;
  final String password;
}

class RegisterParams {
  const RegisterParams({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });

  final String name;
  final String email;
  final String phone;
  final String password;
}

class ForgotPasswordParams {
  const ForgotPasswordParams({required this.email});

  final String email;
}

class VerifyOtpParams {
  const VerifyOtpParams({required this.sessionId, required this.code});

  final String sessionId;
  final String code;
}

class ResetPasswordParams {
  const ResetPasswordParams({
    required this.sessionId,
    required this.password,
    required this.confirmPassword,
  });

  final String sessionId;
  final String password;
  final String confirmPassword;
}
