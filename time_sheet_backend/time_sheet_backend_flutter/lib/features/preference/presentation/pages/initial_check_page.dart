import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  @override
  void initState() {
    super.initState();
    // Check authentication state first
    context.read<AuthBloc>().add(AuthCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Listen to auth state
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthUnauthenticated) {
              // Not logged in → go to login page
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
            } else if (state is AuthAuthenticated) {
              // Logged in → check if onboarding is complete
              context.read<PreferencesBloc>().add(LoadPreferences());
            }
          },
        ),
        // Listen to preferences state (after auth is confirmed)
        BlocListener<PreferencesBloc, PreferencesState>(
          listener: (context, state) {
            // Only proceed if user is authenticated
            final authState = context.read<AuthBloc>().state;
            if (authState is! AuthAuthenticated) return;

            if (state is PreferencesLoaded) {
              if (state.firstName.isEmpty ||
                  state.lastName.isEmpty ||
                  state.company.isEmpty ||
                  state.signature == null) {
                // Missing profile info → onboarding
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const OnboardingPage(),
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
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const OnboardingPage(),
                ),
              );
            }
          },
        ),
      ],
      child: const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
