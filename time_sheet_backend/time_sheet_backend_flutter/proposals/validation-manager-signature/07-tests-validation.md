# Tests et Validation - Système de Validation Manager

## Stratégie de tests

### Pyramide de tests

```
                    ┌─────────┐
                   │   E2E    │  5%
                  ┌┴─────────┴┐
                 │Integration │  15%
               ┌─┴───────────┴─┐
              │   Widget      │  30%
            ┌─┴───────────────┴─┐
           │      Unit         │  50%
           └───────────────────┘
```

## 1. Tests unitaires

### Test du Use Case de soumission

```dart
// test/features/validation/domain/use_cases/submit_validation_usecase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';

@GenerateMocks([
  ValidationRepository,
  PdfGeneratorService,
  EncryptionService,
  NotificationService,
])
import 'submit_validation_usecase_test.mocks.dart';

void main() {
  late SubmitValidationUseCase useCase;
  late MockValidationRepository mockRepository;
  late MockPdfGeneratorService mockPdfService;
  late MockEncryptionService mockEncryptionService;
  late MockNotificationService mockNotificationService;
  
  setUp(() {
    mockRepository = MockValidationRepository();
    mockPdfService = MockPdfGeneratorService();
    mockEncryptionService = MockEncryptionService();
    mockNotificationService = MockNotificationService();
    
    useCase = SubmitValidationUseCase(
      repository: mockRepository,
      pdfService: mockPdfService,
      encryptionService: mockEncryptionService,
      notificationService: mockNotificationService,
    );
  });
  
  group('SubmitValidationUseCase', () {
    final tTimesheet = TimesheetEntry(
      id: '123',
      userId: 'user123',
      organizationId: 'org123',
      month: 11,
      year: 2024,
      entries: [],
    );
    
    const tManagerId = 'manager123';
    final tPdfBytes = Uint8List.fromList([1, 2, 3]);
    final tEncryptedPdf = EncryptedData(
      ciphertext: Uint8List.fromList([4, 5, 6]),
      iv: Uint8List.fromList([7, 8, 9]),
      organizationId: 'org123',
      timestamp: DateTime.now(),
    );
    const tPdfUrl = 'https://storage.example.com/pdf123.pdf';
    
    test('devrait soumettre une validation avec succès', () async {
      // Arrange
      when(mockPdfService.generateWithSignature(
        timesheet: anyNamed('timesheet'),
        includeEmployeeSignature: anyNamed('includeEmployeeSignature'),
      )).thenAnswer((_) async => tPdfBytes);
      
      when(mockEncryptionService.encryptPDF(
        pdfBytes: anyNamed('pdfBytes'),
        organizationId: anyNamed('organizationId'),
        employeeId: anyNamed('employeeId'),
      )).thenAnswer((_) async => tEncryptedPdf);
      
      when(mockRepository.uploadPDF(
        encryptedPdf: anyNamed('encryptedPdf'),
        fileName: anyNamed('fileName'),
      )).thenAnswer((_) async => tPdfUrl);
      
      when(mockRepository.createValidation(any))
        .thenAnswer((invocation) async => invocation.positionalArguments[0]);
      
      when(mockNotificationService.notifyManager(
        managerId: anyNamed('managerId'),
        validation: anyNamed('validation'),
      )).thenAnswer((_) async => null);
      
      when(mockRepository.cacheValidation(any))
        .thenAnswer((_) async => null);
      
      // Act
      final result = await useCase.execute(
        timesheet: tTimesheet,
        managerId: tManagerId,
      );
      
      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (validation) {
          expect(validation.employeeId, tTimesheet.userId);
          expect(validation.managerId, tManagerId);
          expect(validation.status, ValidationStatus.submitted);
          expect(validation.originalPdfUrl, tPdfUrl);
        },
      );
      
      verify(mockPdfService.generateWithSignature(
        timesheet: tTimesheet,
        includeEmployeeSignature: true,
      )).called(1);
      
      verify(mockNotificationService.notifyManager(
        managerId: tManagerId,
        validation: anyNamed('validation'),
      )).called(1);
    });
    
    test('devrait retourner une failure en cas d\'erreur PDF', () async {
      // Arrange
      when(mockPdfService.generateWithSignature(
        timesheet: anyNamed('timesheet'),
        includeEmployeeSignature: anyNamed('includeEmployeeSignature'),
      )).thenThrow(Exception('PDF generation failed'));
      
      // Act
      final result = await useCase.execute(
        timesheet: tTimesheet,
        managerId: tManagerId,
      );
      
      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, contains('PDF generation failed')),
        (_) => fail('Should not return success'),
      );
    });
  });
}
```

### Test du service de chiffrement

```dart
// test/core/services/encryption_service_test.dart
void main() {
  late EncryptionService encryptionService;
  
  setUp(() {
    encryptionService = EncryptionService();
  });
  
  group('EncryptionService', () {
    test('devrait chiffrer et déchiffrer correctement', () async {
      // Arrange
      final originalData = utf8.encode('Hello, World!');
      const organizationId = 'org123';
      
      // Act
      final encrypted = await encryptionService.encrypt(
        data: Uint8List.fromList(originalData),
        organizationId: organizationId,
      );
      
      final decrypted = await encryptionService.decrypt(
        encryptedData: encrypted,
        organizationId: organizationId,
      );
      
      // Assert
      expect(decrypted, equals(originalData));
      expect(encrypted.ciphertext, isNot(equals(originalData)));
    });
    
    test('devrait échouer avec une mauvaise organisation', () async {
      // Arrange
      final data = utf8.encode('Secret data');
      
      final encrypted = await encryptionService.encrypt(
        data: Uint8List.fromList(data),
        organizationId: 'org123',
      );
      
      // Act & Assert
      expect(
        () => encryptionService.decrypt(
          encryptedData: encrypted,
          organizationId: 'wrong_org',
        ),
        throwsA(isA<SecurityException>()),
      );
    });
    
    test('devrait respecter l\'expiration', () async {
      // Arrange
      final data = utf8.encode('Temporary data');
      final encrypted = EncryptedData(
        ciphertext: Uint8List.fromList([1, 2, 3]),
        iv: Uint8List.fromList([4, 5, 6]),
        organizationId: 'org123',
        timestamp: DateTime.now().subtract(Duration(days: 31)),
        expiresAt: DateTime.now().subtract(Duration(days: 1)),
      );
      
      // Act & Assert
      expect(
        () => encryptionService.decrypt(
          encryptedData: encrypted,
          organizationId: 'org123',
        ),
        throwsA(isA<SecurityException>()
          .having((e) => e.message, 'message', contains('expirées'))),
      );
    });
  });
}
```

## 2. Tests de widgets

### Test de la page de soumission

```dart
// test/features/validation/presentation/pages/submit_validation_page_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';

void main() {
  late MockValidationBloc mockBloc;
  late MockManagerRepository mockManagerRepository;
  
  setUp(() {
    mockBloc = MockValidationBloc();
    mockManagerRepository = MockManagerRepository();
  });
  
  Widget makeTestableWidget(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ValidationBloc>.value(value: mockBloc),
      ],
      child: MaterialApp(home: child),
    );
  }
  
  group('SubmitValidationPage', () {
    final tTimesheet = TimesheetEntry(
      id: '123',
      period: '11/2024',
      totalHours: 168,
      workedDays: 20,
    );
    
    testWidgets('devrait afficher le formulaire correctement', (tester) async {
      // Arrange
      when(mockBloc.state).thenReturn(ValidationInitial());
      when(mockManagerRepository.getAvailableManagers())
        .thenAnswer((_) async => [
          Manager(id: 'mgr1', name: 'John Manager', email: 'john@company.com'),
          Manager(id: 'mgr2', name: 'Jane Manager', email: 'jane@company.com'),
        ]);
      
      // Act
      await tester.pumpWidget(
        makeTestableWidget(SubmitValidationPage(timesheet: tTimesheet)),
      );
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('Soumettre pour validation'), findsOneWidget);
      expect(find.text('Période: 11/2024'), findsOneWidget);
      expect(find.text('Total: 168h'), findsOneWidget);
      expect(find.text('John Manager'), findsOneWidget);
      expect(find.text('Jane Manager'), findsOneWidget);
    });
    
    testWidgets('devrait activer le bouton après sélection', (tester) async {
      // Arrange
      when(mockBloc.state).thenReturn(ValidationInitial());
      
      await tester.pumpWidget(
        makeTestableWidget(SubmitValidationPage(timesheet: tTimesheet)),
      );
      await tester.pumpAndSettle();
      
      // Act - Sélectionner un manager
      await tester.tap(find.text('John Manager'));
      await tester.pumpAndSettle();
      
      // Assert
      final submitButton = find.widgetWithText(ElevatedButton, 'Soumettre pour validation');
      expect(submitButton, findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(submitButton).enabled,
        isTrue,
      );
    });
    
    testWidgets('devrait afficher l\'état de chargement', (tester) async {
      // Arrange
      when(mockBloc.state).thenReturn(
        ValidationSubmitting(
          progress: 0.5,
          message: 'Upload en cours...',
        ),
      );
      
      // Act
      await tester.pumpWidget(
        makeTestableWidget(SubmitValidationPage(timesheet: tTimesheet)),
      );
      
      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Upload en cours...'), findsOneWidget);
    });
    
    testWidgets('devrait naviguer après succès', (tester) async {
      // Arrange
      whenListen(
        mockBloc,
        Stream.fromIterable([
          ValidationInitial(),
          ValidationSubmitted(Validation(
            id: '123',
            status: ValidationStatus.submitted,
          )),
        ]),
      );
      
      // Act
      await tester.pumpWidget(
        makeTestableWidget(SubmitValidationPage(timesheet: tTimesheet)),
      );
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('Timesheet soumise avec succès'), findsOneWidget);
    });
  });
}
```

## 3. Tests d'intégration

### Test du flux complet de validation

```dart
// integration_test/validation_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timesheet/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Flux de validation complet', () {
    testWidgets('Un employé peut soumettre et un manager peut valider', (tester) async {
      // Démarrer l'app
      app.main();
      await tester.pumpAndSettle();
      
      // 1. Connexion en tant qu'employé
      await _loginAsEmployee(tester);
      
      // 2. Naviguer vers les timesheets
      await tester.tap(find.text('Time Sheet'));
      await tester.pumpAndSettle();
      
      // 3. Sélectionner une timesheet
      await tester.tap(find.text('Novembre 2024'));
      await tester.pumpAndSettle();
      
      // 4. Soumettre pour validation
      await tester.tap(find.text('Soumettre pour validation'));
      await tester.pumpAndSettle();
      
      // 5. Sélectionner un manager
      await tester.tap(find.text('John Manager'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Soumettre'));
      await tester.pumpAndSettle();
      
      // Vérifier le succès
      expect(find.text('Timesheet soumise avec succès'), findsOneWidget);
      
      // 6. Se déconnecter
      await _logout(tester);
      
      // 7. Se connecter en tant que manager
      await _loginAsManager(tester);
      
      // 8. Naviguer vers les validations
      await tester.tap(find.text('Validations'));
      await tester.pumpAndSettle();
      
      // 9. Ouvrir la validation
      await tester.tap(find.text('Employee Test'));
      await tester.pumpAndSettle();
      
      // 10. Signer
      final signaturePad = find.byType(Signature);
      await tester.dragFrom(
        tester.getCenter(signaturePad),
        Offset(100, 0),
      );
      await tester.pumpAndSettle();
      
      // 11. Valider
      await tester.tap(find.text('Valider'));
      await tester.pumpAndSettle();
      
      // Vérifier le succès
      expect(find.text('Validation réussie'), findsOneWidget);
    });
  });
}

Future<void> _loginAsEmployee(WidgetTester tester) async {
  await tester.enterText(find.byKey(Key('email_field')), 'employee@test.com');
  await tester.enterText(find.byKey(Key('password_field')), 'password123');
  await tester.tap(find.text('Se connecter'));
  await tester.pumpAndSettle();
}

Future<void> _loginAsManager(WidgetTester tester) async {
  await tester.enterText(find.byKey(Key('email_field')), 'manager@test.com');
  await tester.enterText(find.byKey(Key('password_field')), 'password123');
  await tester.tap(find.text('Se connecter'));
  await tester.pumpAndSettle();
}

Future<void> _logout(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Déconnexion'));
  await tester.pumpAndSettle();
}
```

## 4. Tests de performance

### Test de charge pour les uploads

```dart
// test/performance/upload_performance_test.dart
void main() {
  group('Performance des uploads', () {
    test('devrait uploader 100 PDFs en moins de 30 secondes', () async {
      // Arrange
      final service = ValidationService();
      final pdfs = List.generate(100, (i) => _generateTestPdf(i));
      
      // Act
      final stopwatch = Stopwatch()..start();
      
      final futures = pdfs.map((pdf) => 
        service.uploadPDF(pdf, 'test_$pdf.pdf')
      ).toList();
      
      await Future.wait(futures);
      
      stopwatch.stop();
      
      // Assert
      expect(stopwatch.elapsed.inSeconds, lessThan(30));
      print('Upload de 100 PDFs en ${stopwatch.elapsed.inSeconds}s');
    });
    
    test('devrait gérer la concurrence', () async {
      // Tester 50 uploads simultanés
      final futures = List.generate(50, (i) async {
        final validation = await createTestValidation(i);
        return service.submitValidation(validation);
      });
      
      final results = await Future.wait(futures);
      
      // Tous devraient réussir
      expect(results.where((r) => r.isSuccess).length, equals(50));
    });
  });
}
```

## 5. Tests de sécurité

### Test de vulnérabilités

```dart
// test/security/security_test.dart
void main() {
  group('Tests de sécurité', () {
    test('devrait rejeter les injections SQL', () async {
      // Arrange
      final maliciousInput = "'; DROP TABLE users; --";
      
      // Act & Assert
      expect(
        () => repository.findValidationsByEmployee(maliciousInput),
        throwsA(isA<SecurityException>()),
      );
    });
    
    test('devrait valider les entrées utilisateur', () {
      // Test XSS
      final xssPayload = '<script>alert("XSS")</script>';
      final sanitized = InputSanitizer.sanitize(xssPayload);
      
      expect(sanitized, equals('&lt;script&gt;alert(&quot;XSS&quot;)&lt;/script&gt;'));
    });
    
    test('devrait respecter le rate limiting', () async {
      // Tenter 10 connexions rapides
      for (int i = 0; i < 10; i++) {
        try {
          await authService.login('test@test.com', 'wrong_password');
        } catch (e) {
          if (i >= 5) {
            expect(e, isA<RateLimitException>());
          }
        }
      }
    });
    
    test('devrait vérifier les permissions', () async {
      // Un employé ne devrait pas pouvoir valider
      final employee = User(role: 'employee');
      
      expect(
        () => validationService.validateAsManager(
          validationId: '123',
          user: employee,
        ),
        throwsA(isA<PermissionException>()),
      );
    });
  });
}
```

## 6. Tests End-to-End

### Configuration Cypress pour tests E2E

```javascript
// cypress/e2e/validation_flow.cy.js
describe('Flux de validation E2E', () => {
  beforeEach(() => {
    cy.task('db:seed');
    cy.visit('/');
  });
  
  it('Un employé soumet et un manager valide', () => {
    // Login employé
    cy.login('employee@test.com', 'password123');
    
    // Naviguer vers timesheet
    cy.contains('Time Sheet').click();
    cy.contains('Novembre 2024').click();
    
    // Soumettre
    cy.contains('Soumettre pour validation').click();
    cy.contains('John Manager').click();
    cy.contains('button', 'Soumettre').click();
    
    // Vérifier notification
    cy.contains('Timesheet soumise avec succès').should('be.visible');
    
    // Logout
    cy.logout();
    
    // Login manager
    cy.login('manager@test.com', 'password123');
    
    // Vérifier notification badge
    cy.get('[data-testid="notification-badge"]').should('contain', '1');
    
    // Valider
    cy.contains('Validations').click();
    cy.contains('Employee Test').click();
    
    // Signer
    cy.get('[data-testid="signature-pad"]').signatureGesture();
    
    // Valider
    cy.contains('button', 'Valider').click();
    cy.contains('Validation réussie').should('be.visible');
  });
  
  it('Un manager peut signaler des erreurs', () => {
    cy.login('manager@test.com', 'password123');
    
    cy.contains('Validations').click();
    cy.contains('Employee Test').click();
    
    // Signaler erreur
    cy.contains('Signaler une erreur').click();
    
    // Sélectionner les jours
    cy.get('[data-date="2024-11-15"]').click();
    cy.get('[data-date="2024-11-16"]').click();
    
    // Ajouter commentaire
    cy.get('textarea[name="comment"]')
      .type('Les heures du 15 et 16 novembre semblent incorrectes');
    
    // Envoyer
    cy.contains('button', 'Envoyer').click();
    
    // Vérifier
    cy.contains('Feedback envoyé').should('be.visible');
  });
});
```

## 7. Plan de tests

### Matrice de tests

| Fonctionnalité | Unit | Widget | Integration | E2E | Performance | Security |
|----------------|------|--------|-------------|-----|-------------|----------|
| Soumission validation | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Validation manager | ✅ | ✅ | ✅ | ✅ | ⚪ | ✅ |
| Notifications | ✅ | ⚪ | ✅ | ✅ | ⚪ | ⚪ |
| Chiffrement | ✅ | ⚪ | ⚪ | ⚪ | ✅ | ✅ |
| Sync offline | ✅ | ✅ | ✅ | ⚪ | ⚪ | ⚪ |
| Feedback | ✅ | ✅ | ✅ | ✅ | ⚪ | ✅ |

### Critères d'acceptation

- Coverage minimum : 80%
- Tous les tests E2E passent
- Performance : < 2s pour upload PDF
- Sécurité : 0 vulnérabilité critique

## 8. CI/CD Pipeline

```yaml
# .github/workflows/test.yml
name: Tests

on:
  push:
    branches: [main, develop]
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.x'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Run tests
      run: |
        flutter test --coverage
        flutter test integration_test
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage/lcov.info
    
    - name: Security scan
      run: |
        flutter pub audit
        ./scripts/security_check.sh
```