import 'package:nagah/features/auth/data/data_source/auth_remote_data_source.dart';
import 'package:nagah/features/auth/data/data_source/auth_session_local_data_source.dart';
import 'package:nagah/features/auth/data/model/auth_models.dart';
import 'package:nagah/features/auth/domain/model/auth_models.dart';
import 'package:nagah/features/auth/domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource, this._sessionLocalDataSource);

  final AuthRemoteDataSource _remoteDataSource;
  final AuthSessionLocalDataSource _sessionLocalDataSource;

  @override
  Future<AuthUser> login(LoginParams params) async {
    final user = await _remoteDataSource.login(params);
    await _sessionLocalDataSource.saveSession(user);
    return user.toEntity();
  }

  @override
  Future<OtpSession> register(RegisterParams params) async {
    await _sessionLocalDataSource.savePendingRegistration(
      name: params.name,
      email: params.email,
      phone: params.phone,
      password: params.password,
    );
    try {
      final session = await _remoteDataSource.register(params);
      return session.toEntity();
    } catch (error) {
      await _sessionLocalDataSource.clearPendingRegistration();
      rethrow;
    }
  }

  @override
  Future<OtpSession> requestPasswordReset(ForgotPasswordParams params) async {
    final session = await _remoteDataSource.requestPasswordReset(params);
    return session.toEntity();
  }

  @override
  Future<OtpSession> verifyOtp(VerifyOtpParams params) async {
    final session = await _remoteDataSource.verifyOtp(params);
    if (session.purpose == OtpPurpose.register) {
      final pendingRegistration =
          await _sessionLocalDataSource.getPendingRegistration();
      if (pendingRegistration == null) {
        throw Exception(
          'Registration session ended. Please register again to verify your account.',
        );
      }

      await _remoteDataSource.completeRegistration(
        name: pendingRegistration.name,
        email: pendingRegistration.email,
        phone: pendingRegistration.phone,
        password: pendingRegistration.password,
      );
      await _sessionLocalDataSource.clearPendingRegistration();
    }
    return session.toEntity();
  }

  @override
  Future<void> resendOtp(String email) {
    return _remoteDataSource.resendOtp(email);
  }

  @override
  Future<AuthUser> resetPassword(ResetPasswordParams params) async {
    final user = await _remoteDataSource.resetPassword(params);
    await _sessionLocalDataSource.saveSession(user);
    return user.toEntity();
  }

  @override
  Future<AuthUser?> restoreSession() async {
    final localSession = await _sessionLocalDataSource.getSession();
    if (localSession == null) {
      return null;
    }

    final userId = localSession.id;
    if (userId.isEmpty) {
      await _sessionLocalDataSource.clearSession();
      return null;
    }

    try {
      final freshUser = await _remoteDataSource.getCurrentUser(userId);
      final refreshedSession = AuthUserModel(
        id: freshUser.id,
        name: freshUser.name,
        email: freshUser.email,
        role: freshUser.role,
        token: freshUser.id,
      );
      await _sessionLocalDataSource.saveSession(refreshedSession);
      return refreshedSession.toEntity();
    } catch (_) {
      return localSession.toEntity();
    }
  }

  @override
  Future<void> logout() async {
    await _sessionLocalDataSource.clearSession();
    await _sessionLocalDataSource.clearPendingRegistration();
  }
}
