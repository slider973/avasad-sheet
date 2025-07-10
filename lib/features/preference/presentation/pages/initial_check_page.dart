import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:time_sheet/features/preference/presentation/manager/preferences_bloc.dart';
import 'package:time_sheet/features/preference/presentation/pages/onboarding_page.dart';
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
    // Charger les préférences au démarrage
    context.read<PreferencesBloc>().add(LoadPreferences());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PreferencesBloc, PreferencesState>(
      listener: (context, state) {
        if (state is PreferencesLoaded) {
          // Vérifier si les informations essentielles sont présentes
          if (state.firstName.isEmpty || 
              state.lastName.isEmpty || 
              state.company.isEmpty || 
              state.signature == null) {
            // Rediriger vers l'onboarding
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const OnboardingPage(),
              ),
            );
          } else {
            // Rediriger vers la page principale
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const BottomNavigationBarPage(),
              ),
            );
          }
        } else if (state is PreferencesError) {
          // En cas d'erreur, rediriger vers l'onboarding
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const OnboardingPage(),
            ),
          );
        }
      },
      child: const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}