import 'package:equatable/equatable.dart';
import 'package:nagah/features/auth/domain/model/auth_models.dart';

enum AuthStatus { initial, loading, success, error }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.stage = AuthStage.login,
    this.otpSession,
    this.authenticatedUser,
    this.message,
    this.errorMessage,
  });

  final AuthStatus status;
  final AuthStage stage;
  final OtpSession? otpSession;
  final AuthUser? authenticatedUser;
  final String? message;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    AuthStage? stage,
    OtpSession? otpSession,
    AuthUser? authenticatedUser,
    String? message,
    String? errorMessage,
    bool clearMessage = false,
    bool clearError = false,
    bool clearOtpSession = false,
    bool clearAuthenticatedUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      stage: stage ?? this.stage,
      otpSession: clearOtpSession ? null : (otpSession ?? this.otpSession),
      authenticatedUser: clearAuthenticatedUser
          ? null
          : (authenticatedUser ?? this.authenticatedUser),
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    stage,
    otpSession,
    authenticatedUser,
    message,
    errorMessage,
  ];
}
