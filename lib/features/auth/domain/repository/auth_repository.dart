import 'package:nagah/features/auth/domain/model/auth_models.dart';

abstract class AuthRepository {
  Future<AuthUser> login(LoginParams params);
  Future<OtpSession> register(RegisterParams params);
  Future<OtpSession> requestPasswordReset(ForgotPasswordParams params);
  Future<OtpSession> verifyOtp(VerifyOtpParams params);
  Future<AuthUser> resetPassword(ResetPasswordParams params);
}
