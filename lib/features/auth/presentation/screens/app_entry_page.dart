import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nagah/core/network/supabase_rest_client.dart';
import 'package:nagah/features/auth/data/data_source/auth_remote_data_source.dart';
import 'package:nagah/features/auth/data/data_source/auth_session_local_data_source.dart';
import 'package:nagah/features/auth/data/repository_imp/auth_repository_impl.dart';
import 'package:nagah/features/auth/domain/model/auth_models.dart';
import 'package:nagah/features/auth/domain/usecase/auth_usecases.dart';
import 'package:nagah/features/auth/presentation/screens/auth_flow_page.dart';
import 'package:nagah/features/home/presentation/screens/admin_page.dart';
import 'package:nagah/features/home/presentation/screens/home_page.dart';
import 'package:nagah/features/onboarding/screens/onboarding_page.dart';

class AppEntryPage extends StatefulWidget {
  const AppEntryPage({super.key});

  @override
  State<AppEntryPage> createState() => _AppEntryPageState();
}

class _AppEntryPageState extends State<AppEntryPage> {
  late final Future<_LaunchDestination> _launchFuture = _resolveDestination();

  Future<_LaunchDestination> _resolveDestination() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    final repository = AuthRepositoryImpl(
      AuthRemoteDataSource(SupabaseRestClient()),
      AuthSessionLocalDataSource(),
    );

    final restoreSessionUseCase = RestoreSessionUseCase(repository);
    final user = await restoreSessionUseCase();

    return _LaunchDestination(
      hasSeenOnboarding: hasSeenOnboarding,
      user: user,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LaunchDestination>(
      future: _launchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final destination = snapshot.data;
        if (destination == null) {
          return const AuthFlowPage();
        }

        if (!destination.hasSeenOnboarding) {
          return const OnboardingPage();
        }

        final user = destination.user;
        if (user == null) {
          return const AuthFlowPage();
        }

        return user.role == UserRole.admin ? const AdminPage() : const HomePage();
      },
    );
  }
}

class _LaunchDestination {
  const _LaunchDestination({
    required this.hasSeenOnboarding,
    required this.user,
  });

  final bool hasSeenOnboarding;
  final AuthUser? user;
}
