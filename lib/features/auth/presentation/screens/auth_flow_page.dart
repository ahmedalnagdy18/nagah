import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nagah/core/network/supabase_rest_client.dart';
import 'package:nagah/features/auth/data/data_source/auth_remote_data_source.dart';
import 'package:nagah/features/auth/data/repository_imp/auth_repository_impl.dart';
import 'package:nagah/features/auth/domain/model/auth_models.dart';
import 'package:nagah/features/auth/domain/usecase/auth_usecases.dart';
import 'package:nagah/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:nagah/features/auth/presentation/cubits/auth_state.dart';
import 'package:nagah/features/auth/presentation/widgets/forgot_password_screen.dart';
import 'package:nagah/features/auth/presentation/widgets/login_screen.dart';
import 'package:nagah/features/auth/presentation/widgets/otp_screen.dart';
import 'package:nagah/features/auth/presentation/widgets/register_screen.dart';
import 'package:nagah/features/auth/presentation/widgets/reset_password_screen.dart';
import 'package:nagah/features/home/presentation/screens/admin_page.dart';
import 'package:nagah/features/home/presentation/screens/home_page.dart';

class AuthFlowPage extends StatelessWidget {
  const AuthFlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = AuthRepositoryImpl(
      AuthRemoteDataSource(SupabaseRestClient()),
    );

    return BlocProvider(
      create: (_) => AuthCubit(
        loginUseCase: LoginUseCase(repository),
        registerUseCase: RegisterUseCase(repository),
        requestPasswordResetUseCase: RequestPasswordResetUseCase(repository),
        verifyOtpUseCase: VerifyOtpUseCase(repository),
        resetPasswordUseCase: ResetPasswordUseCase(repository),
      ),
      child: const _AuthView(),
    );
  }
}

class _AuthView extends StatelessWidget {
  const _AuthView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.message != current.message ||
          previous.errorMessage != current.errorMessage ||
          previous.authenticatedUser != current.authenticatedUser,
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
          context.read<AuthCubit>().clearMessage();
        }

        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
          context.read<AuthCubit>().clearError();
        }

        if (state.authenticatedUser != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => state.authenticatedUser!.role == UserRole.admin
                  ? const AdminPage()
                  : const HomePage(),
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<AuthCubit>();
        final isLoading = state.status == AuthStatus.loading;

        return switch (state.stage) {
          AuthStage.login => LoginScreen(
            isLoading: isLoading,
            onLogin: ({required email, required password}) {
              cubit.login(email: email, password: password);
            },
            onOpenRegister: cubit.goToRegister,
            onOpenForgotPassword: cubit.goToForgotPassword,
          ),
          AuthStage.register => RegisterScreen(
            isLoading: isLoading,
            onRegister:
                ({
                  required name,
                  required email,
                  required phone,
                  required password,
                }) {
                  cubit.register(
                    name: name,
                    email: email,
                    phone: phone,
                    password: password,
                  );
                },
            onOpenLogin: cubit.goToLogin,
          ),
          AuthStage.forgotPassword => ForgotPasswordScreen(
            isLoading: isLoading,
            onSendOtp: ({required email}) {
              cubit.requestPasswordReset(email: email);
            },
            onBackToLogin: cubit.goToLogin,
          ),
          AuthStage.otp => OtpScreen(
            isLoading: isLoading,
            session: state.otpSession!,
            onVerify: ({required code}) {
              cubit.verifyOtp(code: code);
            },
            onBack: () {
              if (state.otpSession?.purpose == OtpPurpose.register) {
                cubit.goToRegister();
              } else {
                cubit.goToForgotPassword();
              }
            },
          ),
          AuthStage.resetPassword => ResetPasswordScreen(
            isLoading: isLoading,
            onResetPassword: ({required password, required confirmPassword}) {
              cubit.resetPassword(
                password: password,
                confirmPassword: confirmPassword,
              );
            },
          ),
        };
      },
    );
  }
}
