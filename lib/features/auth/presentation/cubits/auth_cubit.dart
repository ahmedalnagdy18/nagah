import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nagah/features/auth/domain/model/auth_models.dart';
import 'package:nagah/features/auth/domain/usecase/auth_usecases.dart';
import 'package:nagah/features/auth/presentation/cubits/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required RequestPasswordResetUseCase requestPasswordResetUseCase,
    required VerifyOtpUseCase verifyOtpUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
    required ResendOtpUseCase resendOtpUseCase,
  }) : _loginUseCase = loginUseCase,
       _registerUseCase = registerUseCase,
       _requestPasswordResetUseCase = requestPasswordResetUseCase,
       _verifyOtpUseCase = verifyOtpUseCase,
       _resetPasswordUseCase = resetPasswordUseCase,
       _resendOtpUseCase = resendOtpUseCase,
       super(const AuthState());

  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final RequestPasswordResetUseCase _requestPasswordResetUseCase;
  final VerifyOtpUseCase _verifyOtpUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;
  final ResendOtpUseCase _resendOtpUseCase;
  String? _pendingRegistrationEmail;
  String? _pendingRegistrationPassword;

  void goToLogin() {
    emit(
      state.copyWith(
        stage: AuthStage.login,
        clearError: true,
        clearMessage: true,
      ),
    );
  }

  void goToRegister() {
    emit(
      state.copyWith(
        stage: AuthStage.register,
        clearError: true,
        clearMessage: true,
      ),
    );
  }

  void goToForgotPassword() {
    emit(
      state.copyWith(
        stage: AuthStage.forgotPassword,
        clearError: true,
        clearMessage: true,
      ),
    );
  }

  Future<void> login({required String email, required String password}) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      final user = await _loginUseCase(
        LoginParams(email: email, password: password),
      );
      emit(
        state.copyWith(
          status: AuthStatus.success,
          authenticatedUser: user,
          message: 'Welcome back, ${user.name}.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      final session = await _registerUseCase(
        RegisterParams(
          name: name,
          email: email,
          phone: phone,
          password: password,
        ),
      );
      emit(
        state.copyWith(
          status: AuthStatus.success,
          stage: AuthStage.otp,
          otpSession: session,
          clearAuthenticatedUser: true,
          message: 'Account created. Verify the OTP code to continue.',
        ),
      );
      _pendingRegistrationEmail = email.trim().toLowerCase();
      _pendingRegistrationPassword = password;
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> requestPasswordReset({required String email}) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      final session = await _requestPasswordResetUseCase(
        ForgotPasswordParams(email: email),
      );
      emit(
        state.copyWith(
          status: AuthStatus.success,
          stage: AuthStage.otp,
          otpSession: session,
          clearAuthenticatedUser: true,
          message: 'OTP was sent successfully.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> verifyOtp({required String code}) async {
    final session = state.otpSession;
    if (session == null) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'OTP session not found. Start again.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      final verifiedSession = await _verifyOtpUseCase(
        VerifyOtpParams(sessionId: session.sessionId, code: code),
      );

      if (session.purpose == OtpPurpose.register) {
        final email = _pendingRegistrationEmail ?? verifiedSession.email;
        final password = _pendingRegistrationPassword;
        if (password == null || password.isEmpty) {
          emit(
            state.copyWith(
              status: AuthStatus.success,
              stage: AuthStage.login,
              otpSession: verifiedSession,
              clearAuthenticatedUser: true,
              message: 'Email verified successfully. Login to continue.',
            ),
          );
          return;
        }

        final user = await _loginUseCase(
          LoginParams(email: email, password: password),
        );
        emit(
          state.copyWith(
            status: AuthStatus.success,
            authenticatedUser: user,
            otpSession: verifiedSession,
            message: 'Account verified successfully.',
          ),
        );
        _pendingRegistrationEmail = null;
        _pendingRegistrationPassword = null;
      } else {
        emit(
          state.copyWith(
            status: AuthStatus.success,
            stage: AuthStage.resetPassword,
            otpSession: verifiedSession,
            message: 'OTP verified. Set your new password now.',
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> resendOtp() async {
    final session = state.otpSession;
    if (session == null) {
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      await _resendOtpUseCase(session.email);
      emit(
        state.copyWith(
          status: AuthStatus.success,
          message: 'A new OTP code was sent successfully.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> resetPassword({
    required String password,
    required String confirmPassword,
  }) async {
    final session = state.otpSession;
    if (session == null) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Reset session not found. Start again.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      final user = await _resetPasswordUseCase(
        ResetPasswordParams(
          sessionId: session.sessionId,
          password: password,
          confirmPassword: confirmPassword,
        ),
      );
      emit(
        state.copyWith(
          status: AuthStatus.success,
          authenticatedUser: user,
          message: 'Password changed successfully.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  void clearMessage() {
    emit(state.copyWith(clearMessage: true));
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }
}
