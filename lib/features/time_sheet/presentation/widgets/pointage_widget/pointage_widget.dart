import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/features/time_sheet/presentation/widgets/pointage_widget/pointage_layout.dart';

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
        setState(() {});
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
        print('Chargement des données persistées du jour ${widget.selectedDate}');
        _chargerDonneesPersistees(widget.selectedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TimeSheetBloc, TimeSheetState>(
      listener: _timeSheetListener,
      builder: (context, state) {
        return PointageLayout(
          etatActuel: _etatActuel,
          dernierPointage: _dernierPointage,
          progression: _progressionAnimation.value,
          pointages: pointages,
          onActionPointage: _actionPointage,
          onModifierPointage: _modifierPointage,
          selectedDate: widget.selectedDate,
        );
      },
    );
  }

  void _timeSheetListener(BuildContext context, TimeSheetState state) {
    if (state is TimeSheetDataState) {
      setState(() {
        _etatActuel = state.entry.currentState;
        _dernierPointage = state.entry.lastPointage;
        _progression = state.entry.progression;
        pointages = state.entry.pointagesList;
        _animerProgression(_progression);
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

    setState(() {
      _dernierPointage = maintenant;
      switch (_etatActuel) {
        case 'Non commencé':
          _etatActuel = 'Entrée';
          _animerProgression(0.25);
          pointages.add({'type': 'Entrée', 'heure': maintenant});
          bloc.add(TimeSheetEnterEvent(maintenant));
          break;
        case 'Entrée':
          _etatActuel = 'Pause';
          _animerProgression(0.5);
          pointages.add({'type': 'Début pause', 'heure': maintenant});
          bloc.add(TimeSheetStartBreakEvent(maintenant));
          break;
        case 'Pause':
          _etatActuel = 'Reprise';
          _animerProgression(0.75);
          pointages.add({'type': 'Fin pause', 'heure': maintenant});
          bloc.add(TimeSheetEndBreakEvent(maintenant));
          break;
        case 'Reprise':
          _etatActuel = 'Sortie';
          _animerProgression(1.0);
          pointages.add({'type': 'Fin de journée', 'heure': maintenant});
          bloc.add(TimeSheetOutEvent(maintenant));
          break;
        case 'Sortie':
          _etatActuel = 'Non commencé';
          _animerProgression(0.0);
          pointages.clear();
          break;
      }
    });
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
      if (nouvelleHeure != null) {
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
}