import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:time_sheet/core/database/powersync_database.dart';
import 'package:time_sheet/core/migration/isar_to_powersync_migration.dart';
import 'package:time_sheet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:time_sheet/features/preference/presentation/manager/preferences_bloc.dart';
import 'package:time_sheet/features/preference/presentation/pages/onboarding_page.dart';
import 'package:time_sheet/features/auth/presentation/pages/login_page.dart';
import 'package:time_sheet/features/bottom_nav_tab/presentation/pages/bottom_navigation_bar.dart';

class InitialCheckPage extends StatefulWidget {
  const InitialCheckPage({super.key});

  @override
  State<InitialCheckPage> createState() => _InitialCheckPageState();
}

class _InitialCheckPageState extends State<InitialCheckPage> {
  String _migrationMessage = '';
  bool _isNavigating = false;
  bool _hasHandledAuth = false;

  @override
  void initState() {
    super.initState();
    // Check authentication state first
    context.read<AuthBloc>().add(AuthCheckRequested());
  }

  Future<void> _runIsarMigrationThenLoadPreferences() async {
    await IsarToPowerSyncMigration.migrateIfNeeded(
      onProgress: (progress, message) {
        if (mounted) {
          setState(() => _migrationMessage = message);
        }
      },
    );
    if (mounted) {
      context.read<PreferencesBloc>().add(LoadPreferences());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Listen to auth state
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthUnauthenticated && !_isNavigating) {
              _isNavigating = true;
              // Not logged in → go to login page
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
            } else if (state is AuthAuthenticated && !_hasHandledAuth) {
              _hasHandledAuth = true;
              // Logged in → connect PowerSync, migrate Isar data, then check onboarding
              PowerSyncDatabaseManager.connect();
              _runIsarMigrationThenLoadPreferences();
            }
          },
        ),
        // Listen to preferences state (after auth is confirmed)
        BlocListener<PreferencesBloc, PreferencesState>(
          listener: (context, state) {
            // Only proceed if user is authenticated
            final authState = context.read<AuthBloc>().state;
            if (authState is! AuthAuthenticated) return;

            if (_isNavigating) return;

            if (state is PreferencesLoaded) {
              _isNavigating = true;
              if (state.firstName.isEmpty ||
                  state.lastName.isEmpty ||
                  state.company.isEmpty ||
                  state.signature == null) {
                // Missing profile info → onboarding
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => OnboardingPage(user: authState.user),
                  ),
                );
              } else {
                // All good → main app
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const BottomNavigationBarPage(),
                  ),
                );
              }
            } else if (state is PreferencesError) {
              _isNavigating = true;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => OnboardingPage(user: authState.user),
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (_migrationMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(_migrationMessage, style: const TextStyle(fontSize: 14)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
