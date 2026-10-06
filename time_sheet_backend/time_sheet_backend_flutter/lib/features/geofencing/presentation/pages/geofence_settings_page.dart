import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:time_sheet/config/theme.dart';
import 'package:time_sheet/features/geofencing/domain/entities/geofence_settings.dart';
import 'package:time_sheet/features/geofencing/domain/entities/geofence_zone.dart';
import 'package:time_sheet/features/geofencing/presentation/bloc/geofence_settings_bloc.dart';
import 'package:time_sheet/features/geofencing/presentation/bloc/geofence_settings_event.dart';
import 'package:time_sheet/features/geofencing/presentation/bloc/geofence_settings_state.dart';
import 'package:time_sheet/features/geofencing/presentation/widgets/zone_card.dart';

/// Écran de réglages du pointage automatique par géolocalisation.
///
/// Le BLoC doit être fourni au-dessus par un [BlocProvider], ou passé
/// directement via [bloc] (pratique pour les tests et les aperçus).
class GeofenceSettingsPage extends StatelessWidget {
  final GeofenceSettingsBloc? bloc;

  const GeofenceSettingsPage({super.key, this.bloc});

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<GeofenceSettingsBloc>.value(
        value: bloc!,
        child: const _GeofenceSettingsView(),
      );
    }
    return const _GeofenceSettingsView();
  }
}

class _GeofenceSettingsView extends StatelessWidget {
  const _GeofenceSettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pointage automatique'),
      ),
      body: BlocConsumer<GeofenceSettingsBloc, GeofenceSettingsState>(
        listenWhen: (previous, current) =>
            current.errorMessage != null &&
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
        },
        builder: (context, state) {
          if (state.status == GeofenceSettingsStatus.initial ||
              state.status == GeofenceSettingsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = state.settings;
          final enabled = settings.enabled;

          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              const _PrivacyBanner(),
              _MainSwitch(settings: settings),
              if (state.errorMessage != null) _ErrorBanner(state.errorMessage!),
              _SectionTitle(
                'Vos lieux',
                enabled: enabled,
              ),
              ZoneCard(
                title: 'Lieu de travail',
                description:
                    'L\'arrivée dans cette zone déclenche votre pointage.',
                icon: Icons.business_outlined,
                zone: settings.workZone,
                enabled: enabled,
                isLocating: state.isLocating,
                onUseCurrentPosition: () =>
                    context.read<GeofenceSettingsBloc>().add(
                          const SetZoneFromCurrentPosition(
                            GeofenceKind.work,
                            'Lieu de travail',
                          ),
                        ),
                onRadiusChanged: (value) =>
                    context.read<GeofenceSettingsBloc>().add(
                          UpdateZoneRadius(GeofenceKind.work, value),
                        ),
                onRemove: () => context
                    .read<GeofenceSettingsBloc>()
                    .add(const RemoveZone(GeofenceKind.work)),
              ),
              ZoneCard(
                title: 'Domicile',
                description:
                    'Si vous oubliez de pointer en partant, l\'heure de sortie '
                    'est reconstituée à votre arrivée chez vous.',
                icon: Icons.home_outlined,
                zone: settings.homeZone,
                enabled: enabled,
                isLocating: state.isLocating,
                onUseCurrentPosition: () =>
                    context.read<GeofenceSettingsBloc>().add(
                          const SetZoneFromCurrentPosition(
                            GeofenceKind.home,
                            'Domicile',
                          ),
                        ),
                onRadiusChanged: (value) =>
                    context.read<GeofenceSettingsBloc>().add(
                          UpdateZoneRadius(GeofenceKind.home, value),
                        ),
                onRemove: () => context
                    .read<GeofenceSettingsBloc>()
                    .add(const RemoveZone(GeofenceKind.home)),
              ),
              _SectionTitle('Automatismes', enabled: enabled),
              _AutomationsCard(settings: settings, enabled: enabled),
              _SectionTitle('Réglages fins', enabled: enabled),
              _FineTuningCard(settings: settings, enabled: enabled),
            ],
          );
        },
      ),
    );
  }
}

/// Bandeau expliquant la fonctionnalité et rassurant sur la vie privée.
class _PrivacyBanner extends StatelessWidget {
  const _PrivacyBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TimeSheetTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, color: TimeSheetTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'L\'application pointe pour vous quand vous arrivez et '
                  'quand vous repartez de votre lieu de travail, et détecte '
                  'vos pauses.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Votre position n\'est jamais enregistrée ni partagée : '
                  'elle reste sur votre appareil et sert uniquement à '
                  'déclencher les pointages.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Interrupteur principal d'activation.
class _MainSwitch extends StatelessWidget {
  final GeofenceSettings settings;

  const _MainSwitch({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SwitchListTile(
        title: const Text(
          'Activer le pointage automatique',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'Nécessite au moins un lieu de travail défini.',
        ),
        value: settings.enabled,
        onChanged: (value) =>
            context.read<GeofenceSettingsBloc>().add(ToggleGeofencing(value)),
      ),
    );
  }
}

/// Bandeau rouge affiché en cas d'erreur persistante.
class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.error),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool enabled;

  const _SectionTitle(this.title, {required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: enabled ? TimeSheetTheme.primary : TimeSheetTheme.grey,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
      ),
    );
  }
}

/// Les trois interrupteurs d'automatisme.
class _AutomationsCard extends StatelessWidget {
  final GeofenceSettings settings;
  final bool enabled;

  const _AutomationsCard({required this.settings, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GeofenceSettingsBloc>();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Pointer mon arrivée'),
            subtitle: const Text(
              'Enregistre l\'heure d\'entrée dès que vous arrivez au travail.',
            ),
            value: settings.autoClockIn,
            onChanged:
                enabled ? (value) => bloc.add(ToggleAutoClockIn(value)) : null,
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Détecter mes pauses'),
            subtitle: const Text(
              'Une sortie puis un retour sont comptés comme une pause.',
            ),
            value: settings.autoBreak,
            onChanged:
                enabled ? (value) => bloc.add(ToggleAutoBreak(value)) : null,
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Pointer ma sortie'),
            subtitle: const Text(
              'Enregistre l\'heure de sortie quand vous quittez le travail.',
            ),
            value: settings.autoClockOut,
            onChanged:
                enabled ? (value) => bloc.add(ToggleAutoClockOut(value)) : null,
          ),
        ],
      ),
    );
  }
}

/// Durée minimale de pause et heure du contrôle d'ambiguïté.
class _FineTuningCard extends StatelessWidget {
  final GeofenceSettings settings;
  final bool enabled;

  const _FineTuningCard({required this.settings, required this.enabled});

  String _formatTime(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(BuildContext context) async {
    final bloc = context.read<GeofenceSettingsBloc>();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.ambiguityCheckHour,
        minute: settings.ambiguityCheckMinute,
      ),
      helpText: 'Heure du contrôle d\'ambiguïté',
    );
    if (picked != null) {
      bloc.add(UpdateAmbiguityCheckTime(picked.hour, picked.minute));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = context.read<GeofenceSettingsBloc>();
    final minutes = settings.breakMinDurationMinutes.clamp(5, 60).toDouble();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Durée minimale d\'une pause',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  '${minutes.round()} min',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Slider(
              value: minutes,
              min: 5,
              max: 60,
              divisions: 11,
              label: '${minutes.round()} min',
              onChanged: enabled
                  ? (value) => bloc.add(UpdateBreakMinDuration(value.round()))
                  : null,
            ),
            Text(
              'Une sortie plus courte n\'est pas comptée comme une pause.',
              style:
                  theme.textTheme.bodySmall?.copyWith(color: TimeSheetTheme.grey),
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule_outlined,
                  color: TimeSheetTheme.primary),
              title: const Text('Heure du contrôle d\'ambiguïté'),
              subtitle: Text(
                'Si vous êtes revenu sans reprendre, l\'app vous demande si '
                'vous mangez ou si vous travaillez.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: TimeSheetTheme.grey),
              ),
              trailing: Text(
                _formatTime(
                  settings.ambiguityCheckHour,
                  settings.ambiguityCheckMinute,
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: enabled ? TimeSheetTheme.primary : TimeSheetTheme.grey,
                ),
              ),
              onTap: enabled ? () => _pickTime(context) : null,
            ),
          ],
        ),
      ),
    );
  }
}
