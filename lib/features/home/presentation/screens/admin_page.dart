import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nagah/core/network/supabase_rest_client.dart';
import 'package:nagah/features/auth/data/data_source/auth_remote_data_source.dart';
import 'package:nagah/features/auth/data/data_source/auth_session_local_data_source.dart';
import 'package:nagah/features/auth/data/repository_imp/auth_repository_impl.dart';
import 'package:nagah/features/auth/domain/usecase/auth_usecases.dart';
import 'package:nagah/features/auth/presentation/screens/auth_flow_page.dart';
import 'package:nagah/features/home/data/data_source/home_remote_data_source.dart';
import 'package:nagah/features/home/data/repository_imp/home_repository_impl.dart';
import 'package:nagah/features/home/domain/usecase/home_usecases.dart';
import 'package:nagah/features/home/presentation/cubits/home_cubit.dart';
import 'package:nagah/features/home/presentation/cubits/home_state.dart';
import 'package:nagah/features/home/presentation/widgets/admin_review_screen.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionLocalDataSource = AuthSessionLocalDataSource();
    final repository = HomeRepositoryImpl(
      HomeRemoteDataSource(SupabaseRestClient(), sessionLocalDataSource),
    );

    return BlocProvider(
      create: (_) => HomeCubit(
        getHomeDashboardUseCase: GetHomeDashboardUseCase(repository),
        selectMapLocationUseCase: SelectMapLocationUseCase(repository),
        recenterMapUseCase: RecenterMapUseCase(repository),
        submitReportUseCase: SubmitReportUseCase(repository),
        updateReportStatusUseCase: UpdateReportStatusUseCase(repository),
      )..initialize(),
      child: _AdminView(sessionLocalDataSource: sessionLocalDataSource),
    );
  }
}

class _AdminView extends StatelessWidget {
  const _AdminView({required this.sessionLocalDataSource});

  final AuthSessionLocalDataSource sessionLocalDataSource;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCubit, HomeState>(
      listenWhen: (previous, current) =>
          previous.message != current.message ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
          context.read<HomeCubit>().clearMessage();
        }

        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
          context.read<HomeCubit>().clearError();
        }
      },
      builder: (context, state) {
        if (state.status == HomeViewStatus.loading || state.dashboard == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final dashboard = state.dashboard!;
        final cubit = context.read<HomeCubit>();
        final logoutUseCase = LogoutUseCase(
          AuthRepositoryImpl(
            AuthRemoteDataSource(SupabaseRestClient()),
            sessionLocalDataSource,
          ),
        );

        return AdminReviewScreen(
          reports: dashboard.reports,
          roads: dashboard.roads,
          onLogout: () => _logout(context, logoutUseCase),
          onDecision: ({required reportId, required status, adminNote}) {
            cubit.updateReportStatus(
              reportId: reportId,
              status: status,
              adminNote: adminNote,
            );
          },
        );
      },
    );
  }

  Future<void> _logout(
    BuildContext context,
    LogoutUseCase logoutUseCase,
  ) async {
    await logoutUseCase();
    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthFlowPage()),
      (route) => false,
    );
  }
}
