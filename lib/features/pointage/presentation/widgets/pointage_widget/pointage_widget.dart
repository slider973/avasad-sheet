import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/features/absence/domain/entities/absence_entity.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_absence.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_layout.dart';

import '../../../../absence/domain/value_objects/absence_type.dart';
import '../../../domain/entities/timesheet_entry.dart';
import '../../pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';

class PointageWidget extends StatefulWidget {
  final TimesheetEntry? entry;
  final DateTime selectedDate;

  const PointageWidget({super.key, this.entry, required this.selectedDate});

  @override
  State<PointageWidget> createState() => _PointageWidgetState();
}

class _PointageWidgetState extends State<PointageWidget>
    with SingleTickerProviderStateMixin {
  String _etatActuel = 'Non commencé';
  DateTime? _dernierPointage;
  double _progression = 0.0;
  List<Map<String, dynamic>> pointages = [];
  Duration _totalDayHours = Duration.zero;
  Duration _totalBreakTime = Duration.zero;
  String _monthlyHoursStatus = '';
  String? _absenceReason;
  AbsenceEntity? _absence;
  TimesheetEntry? _currentEntry;
  Duration _weeklyWorkTime = Duration.zero;
  int _remainingVacationDays = 0;
  final Duration _weeklyTarget = const Duration(hours: 41, minutes: 30);
  final Duration _overtimeHours = Duration.zero;

  late AnimationController _controller;
  late Animation<double> _progressionAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _progressionAnimation = Tween<double>(begin: 0, end: 0).animate(_controller)
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    if (widget.entry != null) {
      // Initialisez les données avec celles de l'entrée
      _etatActuel = widget.entry!.currentState;
      _dernierPointage = widget.entry!.lastPointage;
      _progression = widget.entry!.progression;
      pointages = widget.entry!.pointagesList;
      _animerProgression(_progression);
      _updateBlocWithEntry(widget.entry!);
      print('Chargement des données persistées du jour ${widget.selectedDate}');
    } else {
      // Charger les données au démarrage
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print(
            'Chargement des données persistées du jour ${widget.selectedDate}');
        _chargerDonneesPersistees(widget.selectedDate);
      });
    }
    _loadWeeklyData();
  }
  
  @override
  void didUpdateWidget(PointageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Si la date sélectionnée a changé, recharger les données pour la nouvelle date
    if (oldWidget.selectedDate != widget.selectedDate) {
      print('Date sélectionnée modifiée: ${widget.selectedDate}');
      // Réinitialiser les données et charger celles de la nouvelle date
      _chargerDonneesPersistees(widget.selectedDate);
      _loadWeeklyData();
    }
  }

  void _loadVacationData() {
    final bloc = context.read<TimeSheetBloc>();
    bloc.add(LoadVacationDaysEvent());
  }

  Future<void> _loadWeeklyData() async {
    final bloc = context.read<TimeSheetBloc>();
    final DateTime selectedDate = widget.selectedDate;
    final DateTime startOfWeek =
        selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    Duration weeklyWorkTime = Duration.zero;

    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final formattedDate = DateFormat("dd-MMM-yy").format(date);
      final entry =
          await bloc.getTodayTimesheetEntryUseCase.execute(formattedDate);
      if (entry != null) {
        weeklyWorkTime += entry.calculateDailyTotal();
      }
    }

    if (mounted) {
      setState(() {
        _weeklyWorkTime = weeklyWorkTime;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TimeSheetBloc, TimeSheetState>(
      listener: _timeSheetListener,
      builder: (context, state) {
        if (state is TimeSheetAbsenceSignalee) {
          if (state.absenceReason.isNotEmpty) {
            return PointageAbsence(
              absenceReason: state.absenceReason,
              absence: state.entry.absence,
              onDeleteEntry: () {
                _deleteEntry(state.entry);
                            },
              etatActuel: _etatActuel,
            );
          }
        }
        if (state is TimeSheetDataState) {
          return PointageLayout(
            etatActuel: _etatActuel,
            dernierPointage: _dernierPointage,
            progression: _progressionAnimation.value,
            pointages: pointages,
            onActionPointage: _actionPointage,
            onModifierPointage: _modifierPointage,
            selectedDate: widget.selectedDate,
            onSignalerAbsencePeriode: _signalerAbsencePeriode,
            totalDayHours: _totalDayHours,
            monthlyHoursStatus: _monthlyHoursStatus,
            absenceReason: _absenceReason,
            absence: _absence,
            totalBreakTime: _totalBreakTime,
            onDeleteEntry: () {
              if (_currentEntry != null) {
                _deleteEntry(_currentEntry!);
              }
            },
            weeklyWorkTime: _weeklyWorkTime,
            vacationInfo: state.vacationInfo,
            weeklyTarget: _weeklyTarget,
            overtimeHours: _overtimeHours,
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  void _timeSheetListener(BuildContext context, TimeSheetState state) {
    print('State: PointageWidget $state');
    if (state is TimeSheetDataState) {
      if (!mounted) return;
      setState(() {
        _etatActuel = state.entry.currentState;
        _dernierPointage = state.entry.lastPointage;
        _progression = state.entry.progression;
        pointages = state.entry.pointagesList;
        _animerProgression(_progression);
        // Calculer les heures totales de la journée
        _totalDayHours = _calculateTotalDayHours(pointages);
        // Calculer le temps de pause
        _totalBreakTime = _calculateBreakTime(pointages);

        // Calculer le statut mensuel
        _monthlyHoursStatus = _calculateMonthlyHoursStatus(state.entry);
        _absenceReason = state.entry.absenceReason;
        _absence = state.entry.absence;
        _currentEntry = state.entry;
        _loadWeeklyData();
        _remainingVacationDays = state.vacationInfo.remainingTotal;
      });
    }
  }

  void _actionPointage() {
    final maintenant = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      DateTime.now().hour,
      DateTime.now().minute,
      DateTime.now().second,
    );
    final bloc = context.read<TimeSheetBloc>();

    // Ne pas mettre à jour l'état local, laisser le bloc gérer cela
    switch (_etatActuel) {
      case 'Non commencé':
        bloc.add(TimeSheetEnterEvent(maintenant));
        break;
      case 'Entrée':
        bloc.add(TimeSheetStartBreakEvent(maintenant));
        break;
      case 'Pause':
        bloc.add(TimeSheetEndBreakEvent(maintenant));
        break;
      case 'Reprise':
        bloc.add(TimeSheetOutEvent(maintenant));
        break;
      case 'Sortie':
        // Retour à l'état initial
        final formattedDate = DateFormat('dd-MMM-yy').format(widget.selectedDate);
        bloc.add(LoadTimeSheetDataEvent(formattedDate));
        break;
    }
  }

  void _animerProgression(double nouvelleValeur) {
    _progressionAnimation = Tween<double>(
      begin: _progression,
      end: nouvelleValeur,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _progression = nouvelleValeur;
    _controller.forward(from: 0);
  }

  void _modifierPointage(Map<String, dynamic> pointage) {
    // Implémentez ici la logique pour modifier un pointage
    // Par exemple, vous pourriez ouvrir un dialogue pour sélectionner une nouvelle heure
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(pointage['heure']),
    ).then((nouvelleHeure) {
      if (nouvelleHeure != null && mounted) {
        final bloc = context.read<TimeSheetBloc>();
        final nouveauDateTime = DateTime(
          pointage['heure'].year,
          pointage['heure'].month,
          pointage['heure'].day,
          nouvelleHeure.hour,
          nouvelleHeure.minute,
        );
        bloc.add(
            TimeSheetUpdatePointageEvent(pointage['type'], nouveauDateTime));
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _chargerDonneesPersistees(DateTime date) {
    String formattedDate = DateFormat("dd-MMM-yy").format(date);
    final bloc = context.read<TimeSheetBloc>();
    bloc.add(LoadTimeSheetDataEvent(formattedDate));
  }

  void _updateBlocWithEntry(TimesheetEntry entry) {
    final bloc = context.read<TimeSheetBloc>();
    bloc.add(UpdateTimeSheetDataEvent(entry));
  }

  void _signalerAbsencePeriode(
      DateTime dateDebut,
      DateTime dateFin,
      String type,
      AbsenceType absence,
      String raison,
      String? periode,
      TimeOfDay? startTime,
      TimeOfDay? endTime) {
    final bloc = context.read<TimeSheetBloc>();
    final absenceEntity = AbsenceEntity(startDate: dateDebut, endDate: dateFin, type: absence, motif: raison);
    bloc.add(TimeSheetSignalerAbsencePeriodeEvent(dateDebut, dateFin, type,
        raison, periode, startTime, endTime,  widget.selectedDate, absenceEntity));
    // Convertir TimeOfDay en String si non null
    String? startTimeStr = startTime?.format(context);
    String? endTimeStr = endTime?.format(context);
    // Optionnel : Log pour le débogage
    print(
        'Absence signalée : du ${dateDebut.toString().substring(0, 10)} au ${dateFin.toString().substring(0, 10)}');
    print('Type: $type, Raison: $raison, Période: $periode');
  }

  void _deleteEntry(TimesheetEntry entry) {
    final bloc = context.read<TimeSheetBloc>();
    bloc.add(TimeSheetDeleteEntryEvent(entry.id!));
  }

  Duration _calculateTotalDayHours(List<Map<String, dynamic>> pointages) {
    if (pointages.length < 2) return Duration.zero;

    Duration totalDuration = Duration.zero;
    DateTime? workStart;
    DateTime? pauseStart;

    for (int i = 0; i < pointages.length; i++) {
      String type = pointages[i]['type'];
      DateTime time = pointages[i]['heure'];

      switch (type) {
        case 'Entrée':
          workStart = time;
          break;
        case 'Début pause':
          if (workStart != null) {
            totalDuration += time.difference(workStart);
          }
          pauseStart = time;
          break;
        case 'Fin pause':
          workStart = time;
          break;
        case 'Fin de journée':
          if (workStart != null) {
            totalDuration += time.difference(workStart);
          }
          break;
      }
    }

    return totalDuration;
  }

  Duration _calculateBreakTime(List<Map<String, dynamic>> pointages) {
    Duration totalBreakDuration = Duration.zero;
    DateTime? pauseStart;

    for (var pointage in pointages) {
      String type = pointage['type'];
      DateTime time = pointage['heure'];

      switch (type) {
        case 'Début pause':
          pauseStart = time;
          break;
        case 'Fin pause':
          if (pauseStart != null) {
            totalBreakDuration += time.difference(pauseStart);
          }
          break;
      }
    }

    return totalBreakDuration;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes";
  }

  String _calculateMonthlyHoursStatus(TimesheetEntry entry) {
    // Nous allons utiliser la méthode calculateDailyTotal de l'entrée
    Duration dailyTotal = entry.calculateDailyTotal();

    // Supposons que nous avons un objectif mensuel de 160 heures
    Duration monthlyTarget = Duration(hours: 160);

    // Calculons le nombre de jours ouvrés dans le mois (approximativement 22 jours)
    int workingDaysInMonth = 22;

    // Calculons l'objectif quotidien
    Duration dailyTarget =
        Duration(minutes: monthlyTarget.inMinutes ~/ workingDaysInMonth);

    Duration difference = dailyTarget - dailyTotal;

    if (difference.isNegative) {
      return "Vous avez dépassé l'objectif quotidien de ${_formatDuration(difference.abs())}";
    } else {
      return "Il vous reste ${_formatDuration(difference)} pour atteindre l'objectif quotidien";
    }
  }
}
