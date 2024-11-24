import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_absence.dart';
import '../../../../../enum/absence_motif.dart';
import '../../../../../enum/absence_period.dart';

class AbsenceForm extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime, DateTime, String, AbsenceType, String, String,
      TimeOfDay?, TimeOfDay?) onSignalerAbsencePeriode;

  const AbsenceForm({
    super.key,
    required this.selectedDate,
    required this.onSignalerAbsencePeriode,
  });

  @override
  _AbsenceFormState createState() => _AbsenceFormState();
}

class _AbsenceFormState extends State<AbsenceForm> {
  late DateTime dateDebut;
  late DateTime dateFin;
  AbsenceMotif motif = AbsenceMotif.leaveDay;
  String raison = '';
  AbsenceType absenceType = AbsenceType.vacation;
  AbsencePeriod periode = AbsencePeriod.fullDay;
  bool canChangePeriod = true;
  String? halfDayPeriod;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  @override
  void initState() {
    super.initState();
    dateDebut = widget.selectedDate;
    dateFin = widget.selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Ajouter une absence'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _buildAbsenceTypeSegmentedButton(),
              const SizedBox(height: 16),
              _buildDateRangePicker(),
              const SizedBox(height: 16),
              if (canChangePeriod && motif != AbsenceMotif.other)
                _buildPeriodSegmentedButton(),
              if (periode == AbsencePeriod.halfDay &&
                  motif != AbsenceMotif.other) ...[
                const SizedBox(height: 16),
                _buildTimeRangePicker(),
              ],
              const SizedBox(height: 16),
              if (motif == AbsenceMotif.other) _buildReasonTextField(),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAbsenceTypeSegmentedButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Motif d'absence",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SegmentedButton<AbsenceMotif>(
          segments: AbsenceMotif.values.map((AbsenceMotif value) {
            return ButtonSegment<AbsenceMotif>(
              value: value,
              label: Text(value.value),
            );
          }).toList(),
          selected: {motif},
          onSelectionChanged: (Set<AbsenceMotif> newSelection) {
            setState(() {
              motif = newSelection.first;
              absenceType = _getTypeFromMotif(motif);
            });
          },
        ),
      ],
    );
  }

  _getTypeFromMotif(AbsenceMotif motif) {
    if (motif == AbsenceMotif.leaveDay) {
      return AbsenceType.vacation;
    } else if (motif == AbsenceMotif.other) {
      return AbsenceType.other;
    } else {
      return AbsenceType.sickLeave;
    }
  }

  Widget _buildDateRangePicker() {
    return ElevatedButton(
      onPressed: _selectDateRange,
      child:
          Text('Période: ${_formatDate(dateDebut)} - ${_formatDate(dateFin)}'),
    );
  }

  Widget _buildPeriodSegmentedButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Période d'absence",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SegmentedButton<AbsencePeriod>(
          segments: AbsencePeriod.values.map((AbsencePeriod value) {
            return ButtonSegment<AbsencePeriod>(
              value: value,
              label: Text(value.value),
            );
          }).toList(),
          selected: {periode},
          onSelectionChanged: (Set<AbsencePeriod> newSelection) {
            setState(() {
              periode = newSelection.first;
              if (periode == AbsencePeriod.fullDay) {
                halfDayPeriod = null;
                startTime = null;
                endTime = null;
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildTimeRangePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800)
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 1500.ms, color: Colors.amber.shade400)
                  .shake(hz: 4, curve: Curves.easeInOutCubic),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Attention",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Sélectionner les heures de présence (non d'absence)",
                      style:
                          TextStyle(fontSize: 14, color: Colors.amber.shade900),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _selectTime(isStart: true),
                child: Text(startTime != null
                    ? 'Début: ${startTime!.format(context)}'
                    : 'l\'heure de début'),
              ).animate().scale(
                  delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _selectTime(isStart: false),
                child: Text(endTime != null
                    ? 'Fin: ${endTime!.format(context)}'
                    : 'l\'heure de fin'),
              ).animate().scale(
                  delay: 400.ms, duration: 400.ms, curve: Curves.easeOutBack),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReasonTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Entrez un motif d'absence (Optionnel)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (value) {
            setState(() {
              raison = value;
            });
          },
          decoration: const InputDecoration(
            labelText: "Motif de l'absence",
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 320,
          height: 40,
          child: ElevatedButton(
            onPressed: _submitAbsence,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Valider',
              style: TextStyle(fontSize: 15),
            ),
          ),
        )
      ],
    );
  }

  void _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      locale: const Locale('fr', 'CH'),
      initialDateRange: DateTimeRange(start: dateDebut, end: dateFin),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        canChangePeriod = picked.start == picked.end;
        dateDebut = picked.start;
        dateFin = picked.end;
        if (!canChangePeriod) {
          periode = AbsencePeriod.fullDay;
          halfDayPeriod = null;
        }
      });
    }
  }

  void _selectTime({required bool isStart}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (halfDayPeriod == 'Matin'
              ? const TimeOfDay(hour: 8, minute: 0)
              : const TimeOfDay(hour: 13, minute: 0))
          : (halfDayPeriod == 'Matin'
              ? const TimeOfDay(hour: 12, minute: 0)
              : const TimeOfDay(hour: 17, minute: 0)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  void _resetTimeRange() {
    setState(() {
      startTime = null;
      endTime = null;
    });
  }

  void _submitAbsence() {
    widget.onSignalerAbsencePeriode(dateDebut, dateFin, motif.value,
        absenceType, raison, periode.value, startTime, endTime);
    Navigator.of(context).pop();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
