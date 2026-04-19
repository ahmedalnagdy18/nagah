import 'package:nagah/features/auth/data/data_source/auth_remote_data_source.dart';
import 'package:nagah/features/auth/domain/model/auth_models.dart';
import 'package:nagah/features/auth/domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<AuthUser> login(LoginParams params) async {
    final user = await _remoteDataSource.login(params);
    return user.toEntity();
  }

  @override
  Future<OtpSession> register(RegisterParams params) async {
    final session = await _remoteDataSource.register(params);
    return session.toEntity();
  }

  @override
  Future<OtpSession> requestPasswordReset(ForgotPasswordParams params) async {
    final session = await _remoteDataSource.requestPasswordReset(params);
    return session.toEntity();
  }

  @override
  Future<OtpSession> verifyOtp(VerifyOtpParams params) async {
    final session = await _remoteDataSource.verifyOtp(params);
    return session.toEntity();
  }

  @override
  Future<AuthUser> resetPassword(ResetPasswordParams params) async {
    final user = await _remoteDataSource.resetPassword(params);
    return user.toEntity();
  }
}
