# Implémentation Flutter - Système de Validation

## Structure du projet

```
lib/
├── features/
│   └── validation/
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── validation.dart
│       │   │   ├── validation_feedback.dart
│       │   │   └── manager_assignment.dart
│       │   ├── repositories/
│       │   │   └── validation_repository.dart
│       │   └── use_cases/
│       │       ├── submit_validation_usecase.dart
│       │       ├── validate_timesheet_usecase.dart
│       │       └── send_feedback_usecase.dart
│       ├── data/
│       │   ├── models/
│       │   │   ├── validation_model.dart
│       │   │   └── feedback_model.dart
│       │   ├── datasources/
│       │   │   ├── validation_remote_datasource.dart
│       │   │   └── validation_local_datasource.dart
│       │   └── repositories/
│       │       └── validation_repository_impl.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── validation_bloc.dart
│           │   └── manager_validation_bloc.dart
│           ├── pages/
│           │   ├── submit_validation_page.dart
│           │   ├── manager_validation_page.dart
│           │   └── validation_details_page.dart
│           └── widgets/
│               ├── validation_card.dart
│               ├── signature_pad_widget.dart
│               └── feedback_form.dart
└── core/
    └── services/
        ├── supabase_service.dart
        ├── firebase_service.dart
        └── encryption_service.dart
```

## 1. Entités du domaine

### Entité Validation

```dart
// lib/features/validation/domain/entities/validation.dart
import 'package:equatable/equatable.dart';

class Validation extends Equatable {
  final String id;
  final String organizationId;
  final String employeeId;
  final String employeeName;
  final String managerId;
  final String managerName;
  final int timesheetMonth;
  final int timesheetYear;
  final Map<String, dynamic> timesheetData;
  final String originalPdfUrl;
  final String? signedPdfUrl;
  final ValidationStatus status;
  final DateTime submittedAt;
  final DateTime? validatedAt;
  final DateTime expiresAt;
  final Map<String, dynamic>? metadata;
  
  const Validation({
    required this.id,
    required this.organizationId,
    required this.employeeId,
    required this.employeeName,
    required this.managerId,
    required this.managerName,
    required this.timesheetMonth,
    required this.timesheetYear,
    required this.timesheetData,
    required this.originalPdfUrl,
    this.signedPdfUrl,
    required this.status,
    required this.submittedAt,
    this.validatedAt,
    required this.expiresAt,
    this.metadata,
  });
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  String get period => '$timesheetMonth/$timesheetYear';
  
  Duration? get validationDuration {
    if (validatedAt == null) return null;
    return validatedAt!.difference(submittedAt);
  }
  
  @override
  List<Object?> get props => [
    id,
    employeeId,
    managerId,
    status,
    timesheetMonth,
    timesheetYear,
  ];
  
  Validation copyWith({
    ValidationStatus? status,
    String? signedPdfUrl,
    DateTime? validatedAt,
  }) {
    return Validation(
      id: id,
      organizationId: organizationId,
      employeeId: employeeId,
      employeeName: employeeName,
      managerId: managerId,
      managerName: managerName,
      timesheetMonth: timesheetMonth,
      timesheetYear: timesheetYear,
      timesheetData: timesheetData,
      originalPdfUrl: originalPdfUrl,
      signedPdfUrl: signedPdfUrl ?? this.signedPdfUrl,
      status: status ?? this.status,
      submittedAt: submittedAt,
      validatedAt: validatedAt ?? this.validatedAt,
      expiresAt: expiresAt,
      metadata: metadata,
    );
  }
}

enum ValidationStatus {
  submitted,
  validated,
  rejected,
  error,
  expired;
  
  String get displayName {
    switch (this) {
      case ValidationStatus.submitted:
        return 'En attente';
      case ValidationStatus.validated:
        return 'Validée';
      case ValidationStatus.rejected:
        return 'Rejetée';
      case ValidationStatus.error:
        return 'Erreur';
      case ValidationStatus.expired:
        return 'Expirée';
    }
  }
  
  Color get color {
    switch (this) {
      case ValidationStatus.submitted:
        return Colors.orange;
      case ValidationStatus.validated:
        return Colors.green;
      case ValidationStatus.rejected:
        return Colors.red;
      case ValidationStatus.error:
        return Colors.red;
      case ValidationStatus.expired:
        return Colors.grey;
    }
  }
}
```

## 2. Use Cases

### Submit Validation Use Case

```dart
// lib/features/validation/domain/use_cases/submit_validation_usecase.dart
import 'package:dartz/dartz.dart';

class SubmitValidationUseCase {
  final ValidationRepository _repository;
  final PdfGeneratorService _pdfService;
  final EncryptionService _encryptionService;
  final NotificationService _notificationService;
  
  SubmitValidationUseCase({
    required ValidationRepository repository,
    required PdfGeneratorService pdfService,
    required EncryptionService encryptionService,
    required NotificationService notificationService,
  })  : _repository = repository,
        _pdfService = pdfService,
        _encryptionService = encryptionService,
        _notificationService = notificationService;
  
  Future<Either<Failure, Validation>> execute({
    required TimesheetEntry timesheet,
    required String managerId,
  }) async {
    try {
      // 1. Générer le PDF avec signature employé
      final pdfBytes = await _pdfService.generateWithSignature(
        timesheet: timesheet,
        includeEmployeeSignature: true,
      );
      
      // 2. Chiffrer le PDF
      final encryptedPdf = await _encryptionService.encryptPDF(
        pdfBytes: pdfBytes,
        organizationId: timesheet.organizationId,
        employeeId: timesheet.userId,
      );
      
      // 3. Upload vers Supabase
      final pdfUrl = await _repository.uploadPDF(
        encryptedPdf: encryptedPdf,
        fileName: 'timesheet_${timesheet.period}.pdf',
      );
      
      // 4. Créer la validation
      final validation = Validation(
        id: Uuid().v4(),
        organizationId: timesheet.organizationId,
        employeeId: timesheet.userId,
        employeeName: await _getUserName(timesheet.userId),
        managerId: managerId,
        managerName: await _getUserName(managerId),
        timesheetMonth: timesheet.month,
        timesheetYear: timesheet.year,
        timesheetData: timesheet.toJson(),
        originalPdfUrl: pdfUrl,
        status: ValidationStatus.submitted,
        submittedAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: 30)),
      );
      
      // 5. Sauvegarder dans Supabase
      final savedValidation = await _repository.createValidation(validation);
      
      // 6. Envoyer notification au manager
      await _notificationService.notifyManager(
        managerId: managerId,
        validation: savedValidation,
      );
      
      // 7. Mettre à jour le cache local
      await _repository.cacheValidation(savedValidation);
      
      return Right(savedValidation);
      
    } catch (e) {
      return Left(ValidationFailure(e.toString()));
    }
  }
}
```

## 3. Présentation - BLoC

### Validation BLoC

```dart
// lib/features/validation/presentation/bloc/validation_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class ValidationEvent extends Equatable {
  const ValidationEvent();
}

class SubmitValidation extends ValidationEvent {
  final TimesheetEntry timesheet;
  final String managerId;
  
  const SubmitValidation({
    required this.timesheet,
    required this.managerId,
  });
  
  @override
  List<Object> get props => [timesheet, managerId];
}

class LoadValidations extends ValidationEvent {
  final ValidationFilter? filter;
  
  const LoadValidations({this.filter});
  
  @override
  List<Object?> get props => [filter];
}

class RefreshValidations extends ValidationEvent {
  const RefreshValidations();
  
  @override
  List<Object> get props => [];
}

// States
abstract class ValidationState extends Equatable {
  const ValidationState();
}

class ValidationInitial extends ValidationState {
  @override
  List<Object> get props => [];
}

class ValidationLoading extends ValidationState {
  @override
  List<Object> get props => [];
}

class ValidationSubmitting extends ValidationState {
  final double progress;
  final String message;
  
  const ValidationSubmitting({
    required this.progress,
    required this.message,
  });
  
  @override
  List<Object> get props => [progress, message];
}

class ValidationSubmitted extends ValidationState {
  final Validation validation;
  
  const ValidationSubmitted(this.validation);
  
  @override
  List<Object> get props => [validation];
}

class ValidationsLoaded extends ValidationState {
  final List<Validation> validations;
  final bool hasMore;
  
  const ValidationsLoaded({
    required this.validations,
    this.hasMore = false,
  });
  
  @override
  List<Object> get props => [validations, hasMore];
}

class ValidationError extends ValidationState {
  final String message;
  
  const ValidationError(this.message);
  
  @override
  List<Object> get props => [message];
}

// BLoC
class ValidationBloc extends Bloc<ValidationEvent, ValidationState> {
  final SubmitValidationUseCase _submitValidationUseCase;
  final GetValidationsUseCase _getValidationsUseCase;
  final ValidationRepository _repository;
  
  ValidationBloc({
    required SubmitValidationUseCase submitValidationUseCase,
    required GetValidationsUseCase getValidationsUseCase,
    required ValidationRepository repository,
  })  : _submitValidationUseCase = submitValidationUseCase,
        _getValidationsUseCase = getValidationsUseCase,
        _repository = repository,
        super(ValidationInitial()) {
    on<SubmitValidation>(_onSubmitValidation);
    on<LoadValidations>(_onLoadValidations);
    on<RefreshValidations>(_onRefreshValidations);
  }
  
  Future<void> _onSubmitValidation(
    SubmitValidation event,
    Emitter<ValidationState> emit,
  ) async {
    emit(ValidationSubmitting(progress: 0.1, message: 'Génération du PDF...'));
    
    final result = await _submitValidationUseCase.execute(
      timesheet: event.timesheet,
      managerId: event.managerId,
    );
    
    result.fold(
      (failure) => emit(ValidationError(failure.message)),
      (validation) => emit(ValidationSubmitted(validation)),
    );
  }
  
  Future<void> _onLoadValidations(
    LoadValidations event,
    Emitter<ValidationState> emit,
  ) async {
    emit(ValidationLoading());
    
    try {
      final validations = await _repository.getValidations(
        filter: event.filter,
      );
      
      emit(ValidationsLoaded(validations: validations));
    } catch (e) {
      emit(ValidationError(e.toString()));
    }
  }
}
```

## 4. Pages principales

### Page de soumission

```dart
// lib/features/validation/presentation/pages/submit_validation_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SubmitValidationPage extends StatefulWidget {
  final TimesheetEntry timesheet;
  
  const SubmitValidationPage({
    Key? key,
    required this.timesheet,
  }) : super(key: key);
  
  @override
  State<SubmitValidationPage> createState() => _SubmitValidationPageState();
}

class _SubmitValidationPageState extends State<SubmitValidationPage> {
  String? _selectedManagerId;
  List<Manager> _availableManagers = [];
  
  @override
  void initState() {
    super.initState();
    _loadManagers();
  }
  
  Future<void> _loadManagers() async {
    final managers = await context.read<ManagerRepository>().getAvailableManagers();
    setState(() {
      _availableManagers = managers;
      if (managers.length == 1) {
        _selectedManagerId = managers.first.id;
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Soumettre pour validation'),
        backgroundColor: Colors.teal,
      ),
      body: BlocConsumer<ValidationBloc, ValidationState>(
        listener: (context, state) {
          if (state is ValidationSubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Timesheet soumise avec succès'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(true);
          } else if (state is ValidationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ValidationSubmitting) {
            return _buildSubmittingView(state);
          }
          
          return _buildForm();
        },
      ),
    );
  }
  
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Résumé de la timesheet
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Période: ${widget.timesheet.period}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text('Total: ${widget.timesheet.totalHours}h'),
                  Text('Jours travaillés: ${widget.timesheet.workedDays}'),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Sélection du manager
          Text(
            'Sélectionner votre delivery manager',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 16),
          
          if (_availableManagers.isEmpty)
            Center(child: CircularProgressIndicator())
          else
            ..._ availableManagers.map((manager) => RadioListTile<String>(
              title: Text(manager.name),
              subtitle: Text(manager.email),
              value: manager.id,
              groupValue: _selectedManagerId,
              onChanged: (value) {
                setState(() {
                  _selectedManagerId = value;
                });
              },
            )),
          
          SizedBox(height: 32),
          
          // Bouton de soumission
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedManagerId != null
                  ? () => _submitValidation()
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Soumettre pour validation',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Information
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Votre manager recevra une notification pour valider votre timesheet. La validation expire après 30 jours.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSubmittingView(ValidationSubmitting state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(value: state.progress),
          SizedBox(height: 24),
          Text(state.message),
        ],
      ),
    );
  }
  
  void _submitValidation() {
    context.read<ValidationBloc>().add(
      SubmitValidation(
        timesheet: widget.timesheet,
        managerId: _selectedManagerId!,
      ),
    );
  }
}
```

### Page de validation Manager

```dart
// lib/features/validation/presentation/pages/manager_validation_page.dart
class ManagerValidationPage extends StatefulWidget {
  final Validation validation;
  
  const ManagerValidationPage({
    Key? key,
    required this.validation,
  }) : super(key: key);
  
  @override
  State<ManagerValidationPage> createState() => _ManagerValidationPageState();
}

class _ManagerValidationPageState extends State<ManagerValidationPage> {
  final _signatureController = SignatureController();
  bool _isLoading = false;
  Uint8List? _pdfBytes;
  
  @override
  void initState() {
    super.initState();
    _loadPDF();
  }
  
  Future<void> _loadPDF() async {
    setState(() => _isLoading = true);
    
    try {
      final encryptedPdf = await context
          .read<ValidationRepository>()
          .downloadPDF(widget.validation.originalPdfUrl);
          
      final pdfBytes = await context
          .read<EncryptionService>()
          .decryptPDF(encryptedPdf);
          
      setState(() {
        _pdfBytes = pdfBytes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Validation Timesheet'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.error_outline),
            onPressed: _showFeedbackDialog,
            tooltip: 'Signaler une erreur',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // PDF Viewer
                Expanded(
                  child: _pdfBytes != null
                      ? PdfViewer(pdfBytes: _pdfBytes!)
                      : Center(child: Text('Erreur de chargement')),
                ),
                
                // Zone de signature
                Container(
                  height: 200,
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Signature du manager',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextButton(
                              onPressed: () => _signatureController.clear(),
                              child: Text('Effacer'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Signature(
                          controller: _signatureController,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Boutons d'action
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _rejectValidation,
                          child: Text('Rejeter'),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _validateTimesheet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: Text('Valider'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  
  Future<void> _validateTimesheet() async {
    if (_signatureController.isEmpty) {
      _showError('Veuillez signer avant de valider');
      return;
    }
    
    final signature = await _signatureController.toPngBytes();
    if (signature == null) return;
    
    context.read<ManagerValidationBloc>().add(
      ValidateTimesheet(
        validation: widget.validation,
        managerSignature: signature,
      ),
    );
  }
}
```

## 5. Widgets réutilisables

### Widget de carte de validation

```dart
// lib/features/validation/presentation/widgets/validation_card.dart
class ValidationCard extends StatelessWidget {
  final Validation validation;
  final VoidCallback? onTap;
  
  const ValidationCard({
    Key? key,
    required this.validation,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    validation.employeeName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  _StatusChip(status: validation.status),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Période: ${validation.period}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 4),
              Text(
                'Soumis le ${DateFormat('dd/MM/yyyy').format(validation.submittedAt)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              if (validation.isExpired) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Expiré',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ValidationStatus status;
  
  const _StatusChip({required this.status});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withOpacity(0.5)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: status.color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
```

## 6. Services principaux

### Service Supabase

```dart
// lib/core/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  
  SupabaseService._();
  
  SupabaseClient get client => Supabase.instance.client;
  
  Future<void> initialize() async {
    await Supabase.initialize(
      url: const String.fromEnvironment('SUPABASE_URL'),
      anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      authCallbackUrlHostname: 'login',
      debug: kDebugMode,
    );
    
    // Configuration de l'authentification
    _setupAuthListener();
  }
  
  void _setupAuthListener() {
    client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _onUserSignedIn();
      } else if (event == AuthChangeEvent.signedOut) {
        _onUserSignedOut();
      }
    });
  }
  
  Future<void> _onUserSignedIn() async {
    // Synchroniser le FCM token
    await FirebaseService.instance.syncFCMToken();
    
    // Charger les données utilisateur
    await UserRepository.instance.loadCurrentUser();
  }
  
  Future<void> _onUserSignedOut() async {
    // Nettoyer le cache local
    await CacheService.instance.clear();
    
    // Déconnecter Firebase
    await FirebaseService.instance.signOut();
  }
}
```

## 7. Configuration et initialisation

### Main avec initialisation

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser les services
  await _initializeServices();
  
  // Configuration Bloc Observer
  Bloc.observer = AppBlocObserver();
  
  runApp(MyApp());
}

Future<void> _initializeServices() async {
  // 1. Secure Storage
  await SecureStorageService.initializeMasterKey();
  
  // 2. Supabase
  await SupabaseService.instance.initialize();
  
  // 3. Firebase
  await FirebaseService.instance.initialize();
  
  // 4. Injection de dépendances
  configureDependencies();
  
  // 5. Base locale Isar
  await IsarService.instance.initialize();
  
  // 6. Notifications locales
  await LocalNotificationService.instance.initialize();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<AuthBloc>()..add(CheckAuthStatus()),
        ),
        BlocProvider(
          create: (_) => getIt<ValidationBloc>(),
        ),
        BlocProvider(
          create: (_) => getIt<ManagerValidationBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'Time Sheet',
        theme: _buildTheme(),
        home: AuthWrapper(),
        navigatorKey: NavigationService.navigatorKey,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
```