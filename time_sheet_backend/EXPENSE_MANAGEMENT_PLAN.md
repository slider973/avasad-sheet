# 📊 Plan d'implémentation - Gestion des Notes de Frais (Expense Management)

## 🎯 Objectif

Ajouter une fonctionnalité complète de gestion des notes de frais dans l'application timesheet, permettant de :
- 🚗 Gérer les déplacements avec calcul kilométrique
- 🍽️ Gérer les frais de repas
- 💼 Gérer d'autres frais professionnels
- 📄 Générer des PDF de notes de frais avec signatures
- ✅ Valider les notes de frais par le manager

## 📁 Architecture Clean Architecture

Suivre la structure existante avec une nouvelle feature `expense` :

```
lib/features/expense/
├── domain/
│   ├── entities/
│   │   ├── expense.dart                    # Entity principale
│   │   ├── expense_category.dart           # Catégories de frais
│   │   └── expense_report.dart             # Rapport mensuel de frais
│   ├── repositories/
│   │   └── expense_repository.dart         # Interface repository
│   └── use_cases/
│       ├── create_expense_usecase.dart
│       ├── get_expenses_usecase.dart
│       ├── delete_expense_usecase.dart
│       ├── calculate_mileage_usecase.dart
│       ├── generate_expense_pdf_usecase.dart
│       └── get_monthly_expenses_usecase.dart
├── data/
│   ├── models/
│   │   ├── expense.dart                    # Modèle Isar avec annotations
│   │   └── expense_category.dart
│   ├── repositories/
│   │   └── expense_repository_impl.dart
│   └── data_sources/
│       └── expense_local_data_source.dart
└── presentation/
    ├── pages/
    │   ├── expense_list_page.dart
    │   ├── add_expense_page.dart
    │   └── expense_pdf_preview_page.dart
    ├── widgets/
    │   ├── expense_card.dart
    │   ├── expense_form.dart
    │   └── mileage_calculator_widget.dart
    └── bloc/
        ├── expense_list/
        │   ├── expense_list_bloc.dart
        │   ├── expense_list_event.dart
        │   └── expense_list_state.dart
        └── expense_form/
            ├── expense_form_bloc.dart
            ├── expense_form_event.dart
            └── expense_form_state.dart
```

## 📊 Modèles de données

### 1. Expense Entity (Domain)

```dart
class Expense {
  final int? id;
  final DateTime date;
  final ExpenseCategory category;
  final String description;
  final String currency;
  final double amount;

  // Pour les déplacements
  final double? mileageRate;     // Taux kilométrique (ex: 0.70 CHF/km)
  final int? distanceKm;         // Distance en km
  final String? departureLocation;
  final String? arrivalLocation;

  // Métadonnées
  final String? attachmentPath;  // Chemin vers un justificatif (photo, PDF)
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;          // Synchronisé avec le serveur

  // Validation
  final bool isApproved;
  final String? managerComment;
  final DateTime? approvedAt;
}
```

### 2. ExpenseCategory (Enum)

```dart
enum ExpenseCategory {
  mileage('Déplacement', 'mileage'),
  meal('Frais de repas', 'meal'),
  accommodation('Hébergement', 'accommodation'),
  transport('Transport public', 'transport'),
  parking('Parking', 'parking'),
  other('Autre', 'other');

  final String label;
  final String value;

  const ExpenseCategory(this.label, this.value);
}
```

### 3. ExpenseReport (Regroupement mensuel)

```dart
class ExpenseReport {
  final int month;
  final int year;
  final List<Expense> expenses;
  final double totalAmount;
  final Map<ExpenseCategory, double> amountByCategory;
  final bool isSubmitted;
  final bool isApproved;
  final DateTime? submittedAt;
}
```

### 4. Modèle Isar (Data Layer)

```dart
import 'package:isar/isar.dart';

part 'expense.g.dart';

@collection
class ExpenseModel {
  Id? id;

  @Index()
  late DateTime date;

  @Enumerated(EnumType.name)
  late ExpenseCategory category;

  late String description;
  late String currency;
  late double amount;

  // Déplacements
  double? mileageRate;
  int? distanceKm;
  String? departureLocation;
  String? arrivalLocation;

  // Métadonnées
  String? attachmentPath;
  late DateTime createdAt;
  late DateTime updatedAt;
  late bool isSynced;

  // Validation
  late bool isApproved;
  String? managerComment;
  DateTime? approvedAt;

  // Calculé automatiquement pour les déplacements
  double get calculatedAmount {
    if (category == ExpenseCategory.mileage &&
        mileageRate != null &&
        distanceKm != null) {
      return mileageRate! * distanceKm!;
    }
    return amount;
  }
}
```

## 🔧 Use Cases principaux

### 1. CreateExpenseUseCase

```dart
class CreateExpenseUseCase {
  final ExpenseRepository repository;

  Future<Either<Failure, Expense>> execute({
    required DateTime date,
    required ExpenseCategory category,
    required String description,
    String currency = 'CHF',
    double? amount,
    double? mileageRate,
    int? distanceKm,
    String? departureLocation,
    String? arrivalLocation,
  }) async {
    // Valider les données
    if (category == ExpenseCategory.mileage) {
      if (mileageRate == null || distanceKm == null) {
        return Left(ValidationFailure('Taux et distance requis pour un déplacement'));
      }
      // Calculer automatiquement le montant
      amount = mileageRate * distanceKm;
    }

    final expense = Expense(
      date: date,
      category: category,
      description: description,
      currency: currency,
      amount: amount ?? 0,
      mileageRate: mileageRate,
      distanceKm: distanceKm,
      departureLocation: departureLocation,
      arrivalLocation: arrivalLocation,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: false,
      isApproved: false,
    );

    return repository.createExpense(expense);
  }
}
```

### 2. CalculateMileageUseCase

```dart
class CalculateMileageUseCase {
  /// Calcule le montant d'un déplacement
  double execute({
    required int distanceKm,
    required double mileageRate,
  }) {
    return distanceKm * mileageRate;
  }

  /// Récupère le taux kilométrique par défaut depuis les préférences
  Future<double> getDefaultMileageRate() async {
    // À implémenter : récupérer depuis les préférences utilisateur
    // Par défaut : 0.70 CHF/km (taux suisse standard)
    return 0.70;
  }
}
```

### 3. GenerateExpensePdfUseCase

```dart
class GenerateExpensePdfUseCase {
  final ExpenseRepository repository;
  final GetUserPreferenceUseCase getUserPreferenceUseCase;
  final GetSignatureUseCase getSignatureUseCase;

  Future<Either<Failure, File>> execute({
    required int month,
    required int year,
    String? managerSignature,
  }) async {
    // 1. Récupérer toutes les dépenses du mois
    final expensesResult = await repository.getExpensesForMonth(month, year);

    if (expensesResult.isLeft()) {
      return Left(expensesResult.fold((l) => l, (r) => null)!);
    }

    final expenses = expensesResult.getRight().getOrElse(() => []);

    // 2. Récupérer les infos utilisateur
    final user = await _getUserFromPreferences();

    // 3. Générer le PDF
    final pdf = await _generateExpenseReportPdf(
      expenses: expenses,
      month: month,
      year: year,
      user: user,
      managerSignature: managerSignature,
    );

    return Right(pdf);
  }

  Future<File> _generateExpenseReportPdf({
    required List<Expense> expenses,
    required int month,
    required int year,
    required User user,
    String? managerSignature,
  }) async {
    final pdf = pw.Document();

    // Charger la police et le logo
    final fontData = await rootBundle.load("assets/fonts/helvetica.ttf");
    final ttf = pw.Font.ttf(fontData.buffer.asByteData());
    final logoImage = pw.MemoryImage(await _loadLogo());

    // Calculer le total
    double totalAmount = expenses.fold(0.0, (sum, e) => sum + e.amount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader(logoImage, user, month, year),
          _buildExpenseTable(expenses),
          _buildTotal(totalAmount),
          _buildFooter(user.signature, managerSignature),
        ],
        theme: pw.ThemeData.withFont(base: ttf, bold: ttf),
      ),
    );

    // Sauvegarder le fichier
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/expense_reports/${user.company}';
    await Directory(path).create(recursive: true);

    final monthName = DateFormat('MMMM', 'fr_FR').format(DateTime(year, month));
    final fileName = 'Note_de_frais_${monthName}_$year.pdf';
    final file = File('$path/$fileName');

    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildExpenseTable(List<Expense> expenses) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),    // Ref No
        1: const pw.FlexColumnWidth(2),    // Date
        2: const pw.FlexColumnWidth(5),    // Description
        3: const pw.FlexColumnWidth(2),    // Currency
        4: const pw.FlexColumnWidth(2),    // xch. rate
        5: const pw.FlexColumnWidth(1.5),  // Km
        6: const pw.FlexColumnWidth(3),    // Total
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _cell('Ref No'),
            _cell('Date'),
            _cell('Description'),
            _cell('Currency'),
            _cell('xch. rate'),
            _cell('Km'),
            _cell('Total (in CHF)'),
          ],
        ),
        // Rows
        ...expenses.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final expense = entry.value;

          return pw.TableRow(
            children: [
              _cell('$index'),
              _cell(DateFormat('dd.MMM').format(expense.date)),
              _cell(expense.description),
              _cell(expense.currency),
              _cell(expense.mileageRate?.toStringAsFixed(2) ?? ''),
              _cell(expense.distanceKm?.toString() ?? ''),
              _cell(expense.amount.toStringAsFixed(2)),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _cell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 8)),
    );
  }
}
```

## 🎨 Interface utilisateur

### 1. Page principale - Liste des dépenses

```dart
class ExpenseListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes de frais'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _generatePdf(context),
          ),
        ],
      ),
      body: BlocBuilder<ExpenseListBloc, ExpenseListState>(
        builder: (context, state) {
          if (state is ExpenseListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ExpenseListLoaded) {
            return Column(
              children: [
                _buildMonthSelector(context, state.selectedMonth),
                _buildSummaryCard(state.totalAmount, state.expenses.length),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.expenses.length,
                    itemBuilder: (context, index) {
                      return ExpenseCard(expense: state.expenses[index]);
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddExpensePage()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### 2. Formulaire d'ajout de dépense

```dart
class AddExpensePage extends StatefulWidget {
  @override
  _AddExpensePageState createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  ExpenseCategory _selectedCategory = ExpenseCategory.mileage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter une dépense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Sélecteur de catégorie
            DropdownButtonFormField<ExpenseCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Catégorie'),
              items: ExpenseCategory.values.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat.label),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value!);
              },
            ),

            const SizedBox(height: 16),

            // Formulaire conditionnel selon la catégorie
            if (_selectedCategory == ExpenseCategory.mileage)
              _buildMileageForm()
            else
              _buildStandardForm(),

            const SizedBox(height: 24),

            // Bouton de sauvegarde
            ElevatedButton(
              onPressed: _saveExpense,
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMileageForm() {
    return Column(
      children: [
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Lieu de départ',
            prefixIcon: Icon(Icons.location_on),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Lieu d\'arrivée',
            prefixIcon: Icon(Icons.location_on),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Distance (km)',
            prefixIcon: Icon(Icons.route),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Taux kilométrique (CHF/km)',
            prefixIcon: Icon(Icons.attach_money),
          ),
          keyboardType: TextInputType.number,
          initialValue: '0.70',
        ),
      ],
    );
  }
}
```

## 🔄 Intégration Serverpod

### 1. Protocol YAML

Créer `time_sheet_backend_server/lib/src/protocol/expense.yaml` :

```yaml
class: Expense
table: expenses
fields:
  date: DateTime
  category: String
  description: String
  currency: String
  amount: double
  mileageRate: double?, optional
  distanceKm: int?, optional
  departureLocation: String?, optional
  arrivalLocation: String?, optional
  attachmentPath: String?, optional
  createdAt: DateTime
  updatedAt: DateTime
  isSynced: bool
  isApproved: bool
  managerComment: String?, optional
  approvedAt: DateTime?, optional
  userId: String  # Lien avec l'utilisateur
```

### 2. Endpoint Serverpod

```dart
class ExpenseEndpoint extends Endpoint {
  Future<List<Expense>> getExpensesForMonth(
    Session session,
    int month,
    int year,
    String userId,
  ) async {
    return await Expense.db.find(
      session,
      where: (t) =>
        (t.userId.equals(userId)) &
        (t.date.between(
          DateTime(year, month, 1),
          DateTime(year, month + 1, 0),
        )),
      orderBy: (t) => t.date,
    );
  }

  Future<Expense> createExpense(Session session, Expense expense) async {
    return await Expense.db.insertRow(session, expense);
  }

  Future<bool> deleteExpense(Session session, int expenseId) async {
    await Expense.db.deleteRow(session, expenseId);
    return true;
  }
}
```

## 📋 Checklist d'implémentation

### Phase 1 : Setup & Modèles (2-3h)
- [ ] Créer la structure de dossiers `lib/features/expense/`
- [ ] Créer les entities domain (Expense, ExpenseCategory, ExpenseReport)
- [ ] Créer les modèles Isar avec annotations
- [ ] Créer le protocol Serverpod (expense.yaml)
- [ ] Générer le code (`serverpod generate` + `build_runner`)
- [ ] Créer le repository interface

### Phase 2 : Business Logic (3-4h)
- [ ] Implémenter ExpenseRepositoryImpl avec Isar
- [ ] Créer CreateExpenseUseCase
- [ ] Créer GetExpensesUseCase (mensuel + liste)
- [ ] Créer DeleteExpenseUseCase
- [ ] Créer CalculateMileageUseCase
- [ ] Créer GetMonthlyExpensesUseCase
- [ ] Ajouter les use cases dans injection_container.dart

### Phase 3 : Interface utilisateur (4-5h)
- [ ] Créer ExpenseListBloc (events, states, bloc)
- [ ] Créer ExpenseFormBloc
- [ ] Créer ExpenseListPage
- [ ] Créer AddExpensePage avec formulaire conditionnel
- [ ] Créer ExpenseCard widget
- [ ] Créer MileageCalculatorWidget
- [ ] Ajouter un onglet "Frais" dans la navigation

### Phase 4 : Génération PDF (3-4h)
- [ ] Créer GenerateExpensePdfUseCase
- [ ] Implémenter le template PDF (copier le style timesheet)
- [ ] Ajouter tableau des dépenses
- [ ] Ajouter signatures (employé + manager)
- [ ] Créer ExpensePdfPreviewPage
- [ ] Ajouter bouton "Générer PDF" dans ExpenseListPage

### Phase 5 : Serverpod Integration (2-3h)
- [ ] Créer ExpenseEndpoint côté serveur
- [ ] Implémenter getExpensesForMonth
- [ ] Implémenter createExpense
- [ ] Implémenter deleteExpense
- [ ] Tester avec Bruno collection
- [ ] Synchroniser les données local ↔ serveur

### Phase 6 : Validation & Tests (2-3h)
- [ ] Ajouter validation de formulaire
- [ ] Tester calcul kilométrique
- [ ] Tester génération PDF
- [ ] Tester synchronisation Serverpod
- [ ] Tests unitaires pour use cases
- [ ] Tests d'intégration

## 🎯 Temps estimé total

**16-22 heures** de développement pour une implémentation complète.

## 🚀 Extensions futures

- 📸 Ajout de photos de justificatifs (tickets, factures)
- 🌍 Calcul automatique de distance via API Google Maps
- 💱 Conversion multi-devises
- 📊 Statistiques et graphiques de dépenses
- ✅ Workflow de validation manager (comme pour les timesheets)
- 🔔 Notifications pour les frais en attente de validation
- 📤 Export Excel des notes de frais

## 📝 Notes

- Suivre exactement la même architecture que la feature `pointage` pour la cohérence
- Réutiliser les composants existants (signatures, PDF, BLoC pattern)
- Garder la même approche double storage (Isar local + Serverpod serveur)
- Utiliser les mêmes conventions de nommage et structure de code
