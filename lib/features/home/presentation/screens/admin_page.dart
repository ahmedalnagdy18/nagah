import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nagah/core/network/supabase_rest_client.dart';
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
    final repository = HomeRepositoryImpl(
      HomeRemoteDataSource(SupabaseRestClient()),
    );

    return BlocProvider(
      create: (_) => HomeCubit(
        getHomeDashboardUseCase: GetHomeDashboardUseCase(repository),
        selectMapLocationUseCase: SelectMapLocationUseCase(repository),
        recenterMapUseCase: RecenterMapUseCase(repository),
        submitReportUseCase: SubmitReportUseCase(repository),
        updateReportStatusUseCase: UpdateReportStatusUseCase(repository),
      )..initialize(),
      child: const _AdminView(),
    );
  }
}

class _AdminView extends StatelessWidget {
  const _AdminView();

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

        return AdminReviewScreen(
          reports: dashboard.reports,
          roads: dashboard.roads,
          onDecision: ({required reportId, required status}) {
            cubit.updateReportStatus(reportId: reportId, status: status);
          },
        );
      },
    );
  }
}
