import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/features/time_sheet/presentation/widgets/watch_counter/pointageCard.dart';

import '../../pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';

class PointageWidget extends StatefulWidget {
  @override
  _PointageWidgetState createState() => _PointageWidgetState();
}

class _PointageWidgetState extends State<PointageWidget> with SingleTickerProviderStateMixin {
  DateTime? _dernierPointage;
  String _etatActuel = 'Non commencé';
  late AnimationController _controller;
  late Animation<double> _progressionAnimation;
  double _progression = 0.0;


  List<Map<String, dynamic>> pointages = [];

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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Timer de la journée',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 300,
            height: 300,
            child: CustomPaint(
              painter: TimerPainter(progression: _progressionAnimation.value),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _etatActuel,
                      style: const TextStyle(fontSize: 18),
                    ),
                    Text(
                      _dernierPointage != null
                          ? DateFormat('HH:mm').format(_dernierPointage!)
                          : '00:00',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _construireBoutonAction(),
          SizedBox(height: 20),
          _construireListePointages(),
        ],
      ),
    );
  }

  Widget _construireBoutonAction() {
    final maintenant = DateTime.now();
    String texte;
    Color couleur;
    switch (_etatActuel) {
      case 'Non commencé':
        texte = 'Commencer';
        couleur = Colors.teal;
        break;
      case 'Entrée':
        texte = 'Pause';
        couleur = const Color(0xFF365E32);

        break;
      case 'Pause':
        texte = 'Reprise';
        couleur = const Color(0xFF81A263);

        break;
      case 'Sortie':
        texte = 'Reset';
        couleur = const Color(0xFFE7D37F);
        break;
      default:
        texte = 'Stop';
        couleur = const Color(0xFFFD9B63);
    }

    return SizedBox(
      width: 320,
      height: 40,
      child: ElevatedButton(
        onPressed: _actionPointage,
        style: ElevatedButton.styleFrom(
          backgroundColor: couleur,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          texte,
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }

  Widget _construireListePointages() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pointages.length,
      itemBuilder: (context, index) {
        final pointage = pointages[index];
        return PointageCard(
          type: pointage['type'],
          heure: pointage['heure'],
          onModifier: () => _modifierPointage(pointage),
        );
      },
    );
  }
  void _modifierPointage(Map<String, dynamic> pointage) {
    // Implémentez ici la logique pour modifier un pointage
    // Par exemple, vous pourriez ouvrir un dialogue pour sélectionner une nouvelle heure
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(pointage['heure']),
    ).then((nouvelleHeure) {
      if (nouvelleHeure != null) {
        setState(() {
          pointage['heure'] = DateTime(
            pointage['heure'].year,
            pointage['heure'].month,
            pointage['heure'].day,
            nouvelleHeure.hour,
            nouvelleHeure.minute,
          );
        });
      }
    });
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
          bloc.add(TimeSheetInitialEvent());
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

}

class TimerPainter extends CustomPainter {
  final double progression;

  TimerPainter({required this.progression});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    // Cercle de fond
    final backgroundPaint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Progrès
    final progressPaint = Paint()
      ..color = const Color(0xFF81A263)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progression,
      false,
      progressPaint,
    );

    // Graduations
    final markerPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 0; i < 60; i++) {
      final angle = 2 * pi * i / 60 - pi / 2;
      final markerLength = i % 5 == 0 ? 15.0 : 5.0;
      canvas.drawLine(
        center + Offset(cos(angle) * (radius - markerLength), sin(angle) * (radius - markerLength)),
        center + Offset(cos(angle) * radius, sin(angle) * radius),
        markerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(TimerPainter oldDelegate) => progression != oldDelegate.progression;
}