import 'package:nagah/features/auth/domain/model/auth_models.dart';
import 'package:nagah/features/auth/domain/repository/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call(LoginParams params) => _repository.login(params);
}

class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<OtpSession> call(RegisterParams params) =>
      _repository.register(params);
}

class RequestPasswordResetUseCase {
  const RequestPasswordResetUseCase(this._repository);

  final AuthRepository _repository;

  Future<OtpSession> call(ForgotPasswordParams params) {
    return _repository.requestPasswordReset(params);
  }
}

class VerifyOtpUseCase {
  const VerifyOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<OtpSession> call(VerifyOtpParams params) =>
      _repository.verifyOtp(params);
}

class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call(ResetPasswordParams params) {
    return _repository.resetPassword(params);
  }
}

class ResendOtpUseCase {
  const ResendOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call(String email) => _repository.resendOtp(email);
}

class RestoreSessionUseCase {
  const RestoreSessionUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser?> call() => _repository.restoreSession();
}

class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.logout();
}
