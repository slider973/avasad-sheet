# 💻 Exemples d'Intégration de l'Agent IA

## 🎯 Cas d'usage courants

### 1. Validation avant soumission

```dart
// Dans votre écran de timesheet
Future<void> _submitTimesheet() async {
  // Valider avec l'IA d'abord
  final result = await _aiService.validateEntry(
    entryId: _entry.id,
    date: _entry.date,
    startMorning: _startMorningController.text,
    endMorning: _endMorningController.text,
    startAfternoon: _startAfternoonController.text,
    endAfternoon: _endAfternoonController.text,
  );

  if (!result.isValid) {
    // Afficher les anomalies
    final shouldContinue = await _showValidationWarning(result);
    if (!shouldContinue) return;
  }

  // Continuer la soumission
  await _submitToServer();
}

Future<bool> _showValidationWarning(AiValidationResult result) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('⚠️ Anomalies détectées'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Score: ${result.overallScore.toInt()}/100'),
          const SizedBox(height: 12),
          Text('${result.anomalies.length} anomalie(s) détectée(s)'),
          const SizedBox(height: 8),
          ...result.anomalies.take(3).map((a) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• ${a.description}', style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Corriger'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Soumettre quand même'),
        ),
      ],
    ),
  ) ?? false;
}
```

### 2. Validation en temps réel

```dart
class TimesheetForm extends StatefulWidget {
  @override
  State<TimesheetForm> createState() => _TimesheetFormState();
}

class _TimesheetFormState extends State<TimesheetForm> {
  final _debouncer = Debouncer(milliseconds: 1000);
  AiValidationResult? _validationResult;
  bool _isValidating = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Vos champs de formulaire
        TextFormField(
          decoration: const InputDecoration(labelText: 'Début matin'),
          onChanged: (_) => _validateInRealTime(),
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Fin matin'),
          onChanged: (_) => _validateInRealTime(),
        ),
        // ... autres champs

        // Indicateur de validation en temps réel
        if (_isValidating)
          const LinearProgressIndicator()
        else if (_validationResult != null)
          _buildValidationIndicator(),
      ],
    );
  }

  void _validateInRealTime() {
    _debouncer.run(() async {
      setState(() => _isValidating = true);
      
      try {
        final result = await _aiService.validateEntry(
          entryId: _entry.id,
          date: _entry.date,
          startMorning: _startMorningController.text,
          endMorning: _endMorningController.text,
          startAfternoon: _startAfternoonController.text,
          endAfternoon: _endAfternoonController.text,
        );
        
        setState(() {
          _validationResult = result;
          _isValidating = false;
        });
      } catch (e) {
        setState(() => _isValidating = false);
      }
    });
  }

  Widget _buildValidationIndicator() {
    final score = _validationResult!.overallScore;
    final color = score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(
            score >= 80 ? Icons.check_circle : Icons.warning,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _validationResult!.summary,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            '${score.toInt()}/100',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// Debouncer helper
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
```

### 3. Dashboard d'anomalies

```dart
class AnomalyDashboard extends StatefulWidget {
  @override
  State<AnomalyDashboard> createState() => _AnomalyDashboardState();
}

class _AnomalyDashboardState extends State<AnomalyDashboard> {
  late Future<List<AiAnomalyDetection>> _anomaliesFuture;
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    setState(() {
      _anomaliesFuture = _aiService.getUnresolvedAnomalies(
        startDate: startOfMonth,
        endDate: now,
      );
      _statsFuture = _aiService.getAnomalyStatistics(
        startDate: startOfMonth,
        endDate: now,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Anomalies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistiques
              FutureBuilder<Map<String, dynamic>>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  return _buildStatsCards(snapshot.data!);
                },
              ),
              
              const SizedBox(height: 24),
              
              // Liste des anomalies
              Text(
                'Anomalies non résolues',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              
              FutureBuilder<List<AiAnomalyDetection>>(
                future: _anomaliesFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  
                  return AiAnomalyList(
                    anomalies: snapshot.data!,
                    onResolve: _resolveAnomaly,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards(Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total',
            '${stats['total']}',
            Icons.warning_amber,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Critiques',
            '${stats['bySeverity']['critical'] ?? 0}',
            Icons.error,
            Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Confiance',
            '${(stats['averageConfidence'] * 100).toInt()}%',
            Icons.psychology,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resolveAnomaly(AiAnomalyDetection anomaly) async {
    final success = await _aiService.resolveAnomaly(anomaly.id!, 'user');
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anomalie résolue')),
      );
      _loadData(); // Recharger
    }
  }
}
```

### 4. Validation batch (fin de mois)

```dart
class MonthlyValidation extends StatefulWidget {
  final DateTime month;

  const MonthlyValidation({required this.month});

  @override
  State<MonthlyValidation> createState() => _MonthlyValidationState();
}

class _MonthlyValidationState extends State<MonthlyValidation> {
  bool _isValidating = false;
  List<AiValidationResult>? _results;
  double _progress = 0.0;

  Future<void> _validateMonth() async {
    setState(() {
      _isValidating = true;
      _progress = 0.0;
    });

    try {
      // Récupérer toutes les entrées du mois
      final entries = await _getMonthEntries(widget.month);
      
      // Préparer les données pour la validation batch
      final entriesData = entries.map((e) => {
        'id': e.id,
        'date': e.date.toIso8601String(),
        'startMorning': e.startMorning,
        'endMorning': e.endMorning,
        'startAfternoon': e.startAfternoon,
        'endAfternoon': e.endAfternoon,
        'notes': e.notes,
      }).toList();

      // Valider en batch
      final results = await _aiService.validateMultipleEntries(entriesData);
      
      setState(() {
        _results = results;
        _isValidating = false;
        _progress = 1.0;
      });

      // Afficher le résumé
      _showSummary(results);
    } catch (e) {
      setState(() => _isValidating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _showSummary(List<AiValidationResult> results) {
    final totalAnomalies = results.fold<int>(
      0,
      (sum, r) => sum + r.anomalies.length,
    );
    final avgScore = results.fold<double>(
      0,
      (sum, r) => sum + r.overallScore,
    ) / results.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📊 Résumé de validation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Entrées validées: ${results.length}'),
            Text('Anomalies totales: $totalAnomalies'),
            Text('Score moyen: ${avgScore.toInt()}/100'),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: avgScore / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                avgScore >= 80 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showDetailedResults();
            },
            child: const Text('Voir détails'),
          ),
        ],
      ),
    );
  }

  void _showDetailedResults() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MonthlyValidationResults(results: _results!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Validation ${DateFormat('MMMM yyyy').format(widget.month)}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isValidating) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text('Validation en cours...'),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: LinearProgressIndicator(value: _progress),
              ),
            ] else if (_results != null) ...[
              Icon(Icons.check_circle, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              Text('Validation terminée'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _showDetailedResults,
                child: const Text('Voir les résultats'),
              ),
            ] else ...[
              Icon(Icons.calendar_month, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              Text('Prêt à valider le mois'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _validateMonth,
                child: const Text('Lancer la validation'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<List<TimeSheetEntry>> _getMonthEntries(DateTime month) async {
    // TODO: Implémenter la récupération depuis votre base de données
    return [];
  }
}
```

### 5. Widget de suggestion intelligente

```dart
class SmartSuggestionWidget extends StatelessWidget {
  final AiSuggestion suggestion;
  final VoidCallback onApply;

  const SmartSuggestionWidget({
    required this.suggestion,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        leading: Icon(
          Icons.lightbulb,
          color: Colors.amber.shade700,
        ),
        title: Text(suggestion.title),
        subtitle: Text(
          'Confiance: ${(suggestion.confidence * 100).toInt()}%',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(suggestion.description),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.psychology, size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 6),
                          Text(
                            'Raisonnement IA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(suggestion.reasoning),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Plus tard'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: onApply,
                      icon: const Icon(Icons.check),
                      label: const Text('Appliquer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 6. Notification de validation automatique

```dart
class AutoValidationService {
  final AiValidationService _aiService;
  final LocalNotificationService _notificationService;

  AutoValidationService(this._aiService, this._notificationService);

  /// Valide automatiquement en fin de journée
  Future<void> scheduleEndOfDayValidation() async {
    // Programmer pour 18h00
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 18, 0);
    
    if (now.isAfter(scheduledTime)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await _notificationService.scheduleNotification(
      id: 1,
      title: '🤖 Validation automatique',
      body: 'Voulez-vous valider votre feuille de temps ?',
      scheduledTime: scheduledTime,
      payload: 'auto_validation',
    );
  }

  /// Callback quand la notification est cliquée
  Future<void> handleNotificationTap(String? payload) async {
    if (payload == 'auto_validation') {
      final today = DateTime.now();
      final entry = await _getTodayEntry();
      
      if (entry != null) {
        final result = await _aiService.validateEntry(
          entryId: entry.id,
          date: today,
          startMorning: entry.startMorning,
          endMorning: entry.endMorning,
          startAfternoon: entry.startAfternoon,
          endAfternoon: entry.endAfternoon,
        );

        // Envoyer une notification avec le résultat
        await _notificationService.showNotification(
          id: 2,
          title: result.isValid ? '✅ Validation OK' : '⚠️ Anomalies détectées',
          body: result.summary,
        );
      }
    }
  }

  Future<TimeSheetEntry?> _getTodayEntry() async {
    // TODO: Implémenter
    return null;
  }
}
```

## 🎯 Bonnes pratiques

### 1. Gestion des erreurs

```dart
try {
  final result = await _aiService.validateEntry(...);
  // Traiter le résultat
} on TimeoutException {
  // L'API OpenAI a pris trop de temps
  showError('La validation a pris trop de temps. Réessayez.');
} on SocketException {
  // Pas de connexion internet
  showError('Vérifiez votre connexion internet.');
} catch (e) {
  // Autre erreur
  showError('Erreur: $e');
}
```

### 2. Cache des résultats

```dart
class CachedAiValidationService {
  final AiValidationService _service;
  final Map<String, AiValidationResult> _cache = {};

  Future<AiValidationResult> validateEntry({
    required int entryId,
    required DateTime date,
    required String startMorning,
    required String endMorning,
    required String startAfternoon,
    required String endAfternoon,
  }) async {
    // Créer une clé de cache
    final key = '$entryId-$startMorning-$endMorning-$startAfternoon-$endAfternoon';
    
    // Vérifier le cache
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    // Appeler l'API
    final result = await _service.validateEntry(
      entryId: entryId,
      date: date,
      startMorning: startMorning,
      endMorning: endMorning,
      startAfternoon: startAfternoon,
      endAfternoon: endAfternoon,
    );

    // Mettre en cache
    _cache[key] = result;

    return result;
  }

  void clearCache() => _cache.clear();
}
```

### 3. Rate limiting

```dart
class RateLimitedAiService {
  final AiValidationService _service;
  DateTime? _lastCall;
  static const _minDelay = Duration(seconds: 2);

  Future<AiValidationResult> validateEntry(...) async {
    // Vérifier le délai minimum
    if (_lastCall != null) {
      final elapsed = DateTime.now().difference(_lastCall!);
      if (elapsed < _minDelay) {
        await Future.delayed(_minDelay - elapsed);
      }
    }

    _lastCall = DateTime.now();
    return await _service.validateEntry(...);
  }
}
```

---

**Note** : Tous ces exemples sont prêts à l'emploi. Adaptez-les selon vos besoins spécifiques !
