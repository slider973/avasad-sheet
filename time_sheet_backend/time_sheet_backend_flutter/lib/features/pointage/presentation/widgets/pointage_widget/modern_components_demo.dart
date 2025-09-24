import 'package:flutter/material.dart';
import 'modern_info_card.dart';
import 'time_info_card.dart';
import 'modern_pointage_button.dart';

/// Page de démonstration des nouveaux composants modernisés
/// Utilisée pour tester les composants sur différentes tailles d'écran
class ModernComponentsDemo extends StatelessWidget {
  const ModernComponentsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Composants Modernisés'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('ModernInfoCard'),
            _buildInfoCardExamples(),
            const SizedBox(height: 32),
            _buildSectionTitle('TimeInfoCard'),
            _buildTimeInfoCardExamples(),
            const SizedBox(height: 32),
            _buildSectionTitle('ModernPointageButton'),
            _buildButtonExamples(),
            const SizedBox(height: 32),
            _buildSectionTitle('Responsive Layout'),
            _buildResponsiveExample(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
    );
  }

  Widget _buildInfoCardExamples() {
    return Column(
      children: [
        ModernInfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Carte de base',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Ceci est un exemple de ModernInfoCard avec du contenu personnalisé.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        ModernInfoCardVariants.accent(
          accentColor: Colors.blue,
          child: const Text(
            'Carte avec accent bleu',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        ModernInfoCardVariants.alert(
          alertColor: Colors.orange,
          child: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Carte d\'alerte avec fond coloré',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        ModernInfoCardVariants.compact(
          child: const Text('Carte compacte avec moins d\'espacement'),
        ),
      ],
    );
  }

  Widget _buildTimeInfoCardExamples() {
    return Column(
      children: [
        TimeInfoCardVariants.dailyWork(
          timeValue: '07:45:30',
          subtitle: 'Objectif: 8h00',
          showProgress: true,
          progressValue: 0.97,
        ),

        TimeInfoCardVariants.breakTime(
          timeValue: '00:45:00',
          subtitle: 'Pause en cours',
        ),

        TimeInfoCardVariants.overtime(
          timeValue: '01:15:00',
          subtitle: 'Heures supplémentaires aujourd\'hui',
        ),

        TimeInfoCardVariants.estimatedEnd(
          timeValue: '17:30',
          subtitle: 'Basé sur le rythme actuel',
        ),

        // Exemple compact
        TimeInfoCard(
          title: 'Temps compact',
          timeValue: '04:30:15',
          icon: Icons.timer,
          isCompact: true,
        ),
      ],
    );
  }

  Widget _buildButtonExamples() {
    return Column(
      children: [
        const ModernPointageButton.entry(onPressed: null),
        const SizedBox(height: 12),

        const ModernPointageButton.pause(onPressed: null),
        const SizedBox(height: 12),

        const ModernPointageButton.resume(onPressed: null),
        const SizedBox(height: 12),

        const ModernPointageButton.exit(onPressed: null),
        const SizedBox(height: 12),

        const ModernPointageButton.secondary(
          text: 'Action secondaire',
          icon: Icons.settings,
          onPressed: null,
        ),
        const SizedBox(height: 12),

        // Différentes tailles
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ModernPointageButton(
              text: 'Petit',
              size: PointageButtonSize.small,
              onPressed: () {},
            ),
            ModernPointageButton(
              text: 'Moyen',
              size: PointageButtonSize.medium,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Bouton en chargement
        const ModernPointageButton(
          text: 'Chargement...',
          isLoading: true,
          onPressed: null,
        ),
      ],
    );
  }

  Widget _buildResponsiveExample() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;

        if (isTablet) {
          // Layout tablette - deux colonnes
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    TimeInfoCardVariants.dailyWork(
                      timeValue: '06:30:00',
                      showProgress: true,
                      progressValue: 0.8,
                    ),
                    TimeInfoCardVariants.breakTime(
                      timeValue: '00:30:00',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    TimeInfoCardVariants.overtime(
                      timeValue: '00:45:00',
                    ),
                    TimeInfoCardVariants.estimatedEnd(
                      timeValue: '17:15',
                    ),
                  ],
                ),
              ),
            ],
          );
        } else {
          // Layout mobile - une colonne
          return Column(
            children: [
              TimeInfoCard(
                title: 'Layout Mobile',
                timeValue: '06:30:00',
                subtitle: 'Affichage adaptatif',
                icon: Icons.phone_android,
                isCompact: true,
              ),
              TimeInfoCard(
                title: 'Carte compacte',
                timeValue: '00:30:00',
                icon: Icons.timer,
                isCompact: true,
              ),
            ],
          );
        }
      },
    );
  }
}

/// Widget d'exemple pour tester les interactions
class InteractiveComponentsDemo extends StatefulWidget {
  const InteractiveComponentsDemo({super.key});

  @override
  State<InteractiveComponentsDemo> createState() =>
      _InteractiveComponentsDemoState();
}

class _InteractiveComponentsDemoState extends State<InteractiveComponentsDemo> {
  String _lastAction = 'Aucune action';
  bool _isLoading = false;

  void _handleAction(String action) {
    setState(() {
      _lastAction = action;
      _isLoading = true;
    });

    // Simuler une action asynchrone
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Composants Interactifs'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ModernInfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dernière action:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lastAction,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.teal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ModernPointageButton.entry(
              onPressed: _isLoading ? null : () => _handleAction('Entrée'),
              isLoading: _isLoading,
            ),
            const SizedBox(height: 12),
            ModernPointageButton.pause(
              onPressed: _isLoading ? null : () => _handleAction('Pause'),
              isLoading: _isLoading,
            ),
            const SizedBox(height: 12),
            ModernPointageButton.resume(
              onPressed: _isLoading ? null : () => _handleAction('Reprise'),
              isLoading: _isLoading,
            ),
            const SizedBox(height: 12),
            ModernPointageButton.exit(
              onPressed: _isLoading ? null : () => _handleAction('Sortie'),
              isLoading: _isLoading,
            ),
            const Spacer(),
            TimeInfoCard(
              title: 'Carte interactive',
              timeValue: DateTime.now().toString().substring(11, 19),
              subtitle: 'Tapez pour voir l\'animation',
              icon: Icons.touch_app,
              onTap: () => _handleAction('Carte touchée'),
            ),
          ],
        ),
      ),
    );
  }
}
