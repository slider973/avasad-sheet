import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../pointage/presentation/pages/anomaly/anomaly.dart';
import '../../../pointage/presentation/pages/pdf/pages/pdf_document_page.dart';
import '../../../pointage/presentation/pages/pdf/bloc/anomaly/anomaly_bloc.dart';
import '../../../preference/presentation/pages/preference.dart';
import '../../../pointage/presentation/pages/pointage/pointage_page.dart';
import '../../../pointage/presentation/pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';
import '../../../pointage/presentation/pages/time-sheet/bloc/time_sheet_list/time_sheet_list_bloc.dart';
import '../../../pointage/presentation/widgets/timesheet_calendar_widget/timesheet_calendar_widget.dart';
import '../widgets/bottom_navigation_bar_widget.dart';
import 'app_drawer.dart';
import 'bloc/bottom_navigation_bar_bloc.dart';
import '../../../../services/request_permission_handler.dart' as permission;

class BottomNavigationBarPage extends StatefulWidget {
  const BottomNavigationBarPage({super.key});

  @override
  State<BottomNavigationBarPage> createState() =>
      _BottomNavigationBarPageState();
}

class _BottomNavigationBarPageState extends State<BottomNavigationBarPage> {
  // Liste des écrans pré-initialisés pour conserver leur état
  late List<Widget> _screens;
  
  // Cache temporel pour éviter les rafraîchissements excessifs
  DateTime? _lastAnomalyUpdate;
  static const Duration _anomalyCacheWindow = Duration(minutes: 2);
  
  @override
  void initState() {
    super.initState();
    _checkPermissions();
    
    // Initialiser tous les écrans une seule fois
    _screens = [
      const PointagePage(),
      PdfDocumentPage(),
      const TimesheetCalendarWidget(),
      AnomalyView(),
      PreferencesPage(),
    ];
    
    // Charger les anomalies dès le démarrage pour le badge
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnomalyBloc>().add(const DetectAnomalies());
    });
  }

  Future<void> _checkPermissions() async {
    await permission.handlePermission(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: const AppDrawer(),
        body: BlocConsumer<BottomNavigationBarBloc, int>(
          listener: (context, currentIndex) {
            // Si l'utilisateur navigue vers l'onglet pointage (index 0),
            // forcer le chargement des données du jour actuel
            if (currentIndex == 0) {
              // Formater la date d'aujourd'hui dans le format attendu par le BLoC
              final today = DateTime.now();
              final formattedDate = DateFormat("dd-MMM-yy").format(today);
              
              // Déclencher le chargement des données pour aujourd'hui
              final bloc = context.read<TimeSheetBloc>();
              bloc.add(LoadTimeSheetDataEvent(formattedDate));
              
              // Mettre à jour les anomalies en arrière-plan pour le badge
              _updateAnomaliesBadge(context);
            }
            // Si l'utilisateur navigue vers l'onglet calendrier (index 2),
            // forcer le rechargement des données du calendrier
            else if (currentIndex == 2) {
              final timeSheetListBloc = context.read<TimeSheetListBloc>();
              timeSheetListBloc.add(const FindTimesheetEntriesEvent());
              
              // Mettre à jour les anomalies en arrière-plan pour le badge
              _updateAnomaliesBadge(context);
            }
            // Si l'utilisateur navigue vers l'onglet anomalies (index 3),
            // forcer le rechargement des anomalies seulement si nécessaire
            else if (currentIndex == 3) {
              if (_shouldForceAnomalyUpdate()) {
                final anomalyBloc = context.read<AnomalyBloc>();
                // Forcer la régénération des anomalies pour s'assurer qu'elles sont à jour
                anomalyBloc.add(const DetectAnomalies(forceRegenerate: true));
                _lastAnomalyUpdate = DateTime.now();
              }
            }
            // Pour les autres onglets, mettre à jour les anomalies en arrière-plan
            else {
              _updateAnomaliesBadge(context);
            }
          },
          builder: (context, currentIndex) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: IndexedStack(
                    index: currentIndex,
                    children: _screens,
                  ),
                ),
                const BottomNavigationBarWidget(),
              ],
            );
          },
        ));
  }

  /// Met à jour les anomalies en arrière-plan pour le badge (sans interferer avec l'UI)
  void _updateAnomaliesBadge(BuildContext context) {
    final now = DateTime.now();
    
    // Vérifier si le cache est encore valide
    if (_lastAnomalyUpdate != null && 
        now.difference(_lastAnomalyUpdate!) < _anomalyCacheWindow) {
      return; // Cache encore valide, ne pas recharger
    }
    
    // Ne pas recharger les anomalies si elles sont déjà en cours de chargement
    final currentState = context.read<AnomalyBloc>().state;
    if (currentState is AnomalyLoading) {
      return; // Déjà en cours de chargement
    }
    
    // Charger les anomalies uniquement si nécessaire
    if (currentState is AnomalyInitial || currentState is AnomalyError) {
      context.read<AnomalyBloc>().add(const DetectAnomalies());
      _lastAnomalyUpdate = now;
    }
  }
  
  /// Vérifie si une mise à jour forcée des anomalies est nécessaire
  bool _shouldForceAnomalyUpdate() {
    final now = DateTime.now();
    return _lastAnomalyUpdate == null || 
           now.difference(_lastAnomalyUpdate!) > _anomalyCacheWindow;
  }
}
