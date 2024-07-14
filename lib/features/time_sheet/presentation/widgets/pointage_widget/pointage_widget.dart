import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:time_sheet/features/time_sheet/presentation/widgets/pointage_widget/pointage_layout.dart';

import '../../pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';

class PointageWidget extends StatefulWidget {
  const PointageWidget({super.key});

  @override
  State<PointageWidget> createState() => _PointageWidgetState();
}

class _PointageWidgetState extends State<PointageWidget>  with SingleTickerProviderStateMixin {
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
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressionAnimation = Tween<double>(begin: 0, end: 0).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
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
    final maintenant = DateTime.now();
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
        bloc.add(TimeSheetUpdatePointageEvent(pointage['type'], nouveauDateTime));
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
