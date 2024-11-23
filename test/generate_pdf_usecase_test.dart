import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fpdart/fpdart.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:time_sheet/features/pointage/domain/repositories/timesheet_repository.dart';
import 'package:time_sheet/features/pointage/use_cases/generate_pdf_usecase.dart';
import 'package:time_sheet/features/preference/domain/use_cases/get_signature_usecase.dart';
import 'package:time_sheet/features/preference/domain/use_cases/get_user_preference_use_case.dart';

// Generate mocks
@GenerateMocks([TimesheetRepository, GetSignatureUseCase, GetUserPreferenceUseCase])
import 'generate_pdf_usecase_test.mocks.dart';
import 'test_utils.dart';

class MockDirectory extends Mock implements Directory {
  @override
  String get path => '/mock/path';

  @override
  Future<Directory> create({bool recursive = false}) async => this;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GeneratePdfUseCase generatePdfUseCase;
  late MockTimesheetRepository mockRepository;
  late MockGetSignatureUseCase mockGetSignatureUseCase;
  late MockGetUserPreferenceUseCase mockGetUserPreferenceUseCase;

  setUp(() {
    mockRepository = MockTimesheetRepository();
    mockGetSignatureUseCase = MockGetSignatureUseCase();
    mockGetUserPreferenceUseCase = MockGetUserPreferenceUseCase();
    generatePdfUseCase = GeneratePdfUseCase(
      repository: mockRepository,
      getSignatureUseCase: mockGetSignatureUseCase,
      getUserPreferenceUseCase: mockGetUserPreferenceUseCase,
    );

    // Mock asset bundle
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
          (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.getData') {
          return null;
        }
        return null;
      },
    );
  });

  test('execute should return Right with file path on success', () async {
    // Arrange
    const int monthNumber = 10;
    final mockEntries = generateMockTimeSheetEntries(
      monthNumber: monthNumber,
      year: 2023,
      includeWeekends: false,
    );

    when(mockRepository.findEntriesFromMonthOf(monthNumber))
        .thenAnswer((_) async => mockEntries);
    when(mockGetUserPreferenceUseCase.execute('firstName'))
        .thenAnswer((_) async => 'John');
    when(mockGetUserPreferenceUseCase.execute('lastName'))
        .thenAnswer((_) async => 'Doe');
    when(mockGetUserPreferenceUseCase.execute('isDeliveryManager'))
        .thenAnswer((_) async => 'false');
    when(mockGetSignatureUseCase.execute())
        .thenAnswer((_) async => null);

    // Act
    final result = await generatePdfUseCase.execute(monthNumber);

    // Assert
    expect(result.isRight(), true);
    result.fold(
          (l) => fail('Should not return Left'),
          (r) => expect(r, contains('/mock/path')),
    );
  });

  test('execute should return Left when no entries are found', () async {
    // Arrange
    const int monthNumber = 10;
    when(mockRepository.findEntriesFromMonthOf(monthNumber))
        .thenAnswer((_) async => []);

    // Act
    final result = await generatePdfUseCase.execute(monthNumber);

    // Assert
    expect(result.isLeft(), true);
    result.fold(
          (l) => expect(l, contains('Aucune entrée trouvée pour ce mois')),
          (r) => fail('Should not return Right'),
    );
  });

  test('execute should return Left with error message on failure', () async {
    // Arrange
    const int monthNumber = 10;
    when(mockRepository.findEntriesFromMonthOf(monthNumber))
        .thenThrow(Exception('Database error'));

    // Act
    final result = await generatePdfUseCase.execute(monthNumber);

    // Assert
    expect(result.isLeft(), true);
    result.fold(
          (l) => expect(l, contains('Erreur lors de la génération du PDF')),
          (r) => fail('Should not return Right'),
    );
  });

  // Add more tests for other methods like _generatePdf, _getUserFromPreferences, etc.
}