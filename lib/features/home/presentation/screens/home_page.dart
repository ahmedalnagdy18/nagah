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
import 'package:nagah/features/home/presentation/screens/map_page.dart';
import 'package:nagah/features/home/presentation/widgets/my_reports_screen.dart';
import 'package:nagah/features/home/presentation/widgets/report_composer_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
      child: _HomeView(sessionLocalDataSource: sessionLocalDataSource),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView({required this.sessionLocalDataSource});

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

        final pages = [
          MapPage(
            roads: dashboard.roads,
            approvedReports: dashboard.approvedReports,
            currentLocation: dashboard.currentLocation,
            selectedLocation: dashboard.selectedLocation,
            onLocationSelected: cubit.selectMapLocation,
            onCreateReportTap: cubit.openReportComposer,
            onRecenterTap: cubit.recenterMap,
            onLogoutTap: () => _logout(context, logoutUseCase),
          ),
          ReportComposerScreen(
            roads: dashboard.roads
                .where((road) => !road.id.startsWith('fallback-road-'))
                .toList(),
            selectedLocation:
                dashboard.selectedLocation ?? dashboard.currentLocation,
            onLogout: () => _logout(context, logoutUseCase),
            onSubmit:
                ({
                  required roadId,
                  required issueType,
                  required description,
                  required imagePath,
                }) {
                  cubit.submitReport(
                    roadId: roadId,
                    issueType: issueType,
                    description: description,
                    imagePath: imagePath,
                  );
                },
          ),
          MyReportsScreen(
            reports: dashboard.myReports,
            roads: dashboard.roads,
            onRefresh: () => cubit.refreshDashboard(silent: true),
            onLogout: () => _logout(context, logoutUseCase),
          ),
        ];

        return Scaffold(
          body: IndexedStack(index: state.currentTab, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: state.currentTab,
            onDestinationSelected: cubit.changeTab,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map_rounded),
                label: 'Map',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_circle_outline_rounded),
                selectedIcon: Icon(Icons.add_circle_rounded),
                label: 'Report',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'My reports',
              ),
            ],
          ),
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
