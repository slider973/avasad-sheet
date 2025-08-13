import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:time_sheet/features/absence/domain/entities/absence_entity.dart';
import 'package:time_sheet/features/absence/domain/value_objects/absence_type.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_remove_timesheet_day.dart';
import '../../../../../enum/absence_motif.dart';

class PointageAbsence extends StatefulWidget {
  final String? absenceReason;
  final AbsenceEntity? absence;
  final VoidCallback onDeleteEntry;
  final String etatActuel;

  const PointageAbsence({
    super.key,
    this.absenceReason,
    required this.onDeleteEntry,
    required this.etatActuel,
    this.absence,
  });

  @override
  _PointageAbsenceState createState() => _PointageAbsenceState();
}

class _PointageAbsenceState extends State<PointageAbsence> {
  late String _currentPhrase;
  final _phrases = [
    "La plage m'appelle, je réponds présent !",
    "En train de recharger mes batteries... Ne pas déranger !",
    "Si vous me cherchez, je suis quelque part entre le hamac et la piscine.",
    "Aujourd'hui, mon seul objectif est de ne rien faire !",
    "En mission spéciale : tester tous les cocktails du bar de la plage.",
  ];

  @override
  void initState() {
    super.initState();
    _currentPhrase = _getRandomPhrase();
  }

  String _getRandomPhrase() {
    return _phrases[DateTime.now().microsecond % _phrases.length];
  }

  void _changePhrase() {
    setState(() {
      _currentPhrase = _getRandomPhrase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final absenceType = _getAbsenceType(widget.absenceReason);
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLottieAnimation(absenceType),
            _buildTitle(context, absenceType),
            SizedBox(height: 10),
            _buildAnimatedSubtitle(context, absenceType),
            SizedBox(height: 20),
            _buildInfoCard(context, absenceType),
            SizedBox(height: 20),
            PointageRemoveTimesheetDay(
              etatActuel: widget.etatActuel,
              onDeleteEntry: widget.onDeleteEntry,
              isDisabled: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLottieAnimation(AbsenceType type) {
    String animationPath;
    switch (type) {
      case AbsenceType.vacation:
        animationPath = 'assets/animation/vacation.json';
        break;
      case AbsenceType.publicHoliday || AbsenceType.other:
        animationPath = 'assets/animation/holiday.json';
        break;
      case AbsenceType.sickLeave:
        animationPath = 'assets/animation/sick.json';
        break;
    }
    return Lottie.asset(animationPath, width: 300, height: 300);
  }

  Widget _buildTitle(BuildContext context, AbsenceType type) {
    String title;
    Color color;
    switch (type) {
      case AbsenceType.vacation:
        title = 'Profitez de vos vacances !';
        color = Colors.blue;
        break;
      case AbsenceType.publicHoliday:
        title = 'Jour férié';
        color = Colors.green;
        break;
      case AbsenceType.other:
        title = 'Jour de congé';
        color = Colors.green;
      case AbsenceType.sickLeave:
        title = 'Prenez soin de vous';
        color = Colors.orange;
        break;
    }
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildAnimatedSubtitle(BuildContext context, AbsenceType type) {
    String subtitle;
    switch (type) {
      case AbsenceType.vacation:
        subtitle = _currentPhrase;
        break;
      case AbsenceType.publicHoliday:
        subtitle = 'Profitez de cette journée de repos !';
        break;
      case AbsenceType.sickLeave:
        subtitle = 'Reposez-vous bien pour un prompt rétablissement.';
        break;
      case AbsenceType.other:
        subtitle = 'Absence non spécifiée';
        break;
    }

    return GestureDetector(
      onTap: type == AbsenceType.vacation ? _changePhrase : null,
      child: Container(
        height: 60,
        width: 300,
        child: Center(
          child: Animate(
            effects: [
              FadeEffect(duration: 500.ms),
              SlideEffect(
                  duration: 500.ms, begin: Offset(0, 0.1), end: Offset.zero),
            ],
            child: Text(
              subtitle,
              key: ValueKey(subtitle),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true)),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, AbsenceType type) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Détails de l\'absence',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Divider(),
            _buildInfoRow(
                context,
                'Raison',
                widget.absence!.motif.isNotEmpty
                    ? widget.absence!.motif
                    : getMotifFromType()),
          ],
        ),
      ),
    );
  }

  String getMotifFromType() {
    switch (widget.absence!.type) {
      case AbsenceType.vacation:
        return AbsenceMotif.leaveDay.value;
      case AbsenceType.publicHoliday:
        return AbsenceMotif.other.value;
      case AbsenceType.sickLeave:
        return AbsenceMotif.sickness.value;
      case AbsenceType.other:
        return AbsenceMotif.other.value;
    }
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  AbsenceType _getAbsenceType(String? reason) {
    if (reason == null) return AbsenceType.vacation;
    if (reason.toLowerCase() == AbsenceMotif.leaveDay.value.toLowerCase()) {
      return AbsenceType.vacation;
    } else if (reason.toLowerCase() == AbsenceMotif.other.value.toLowerCase()) {
      return AbsenceType.vacation;
    } else {
      return AbsenceType.sickLeave;
    }
  }
}

