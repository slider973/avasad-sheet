// Mocks generated by Mockito 5.4.4 from annotations
// in time_sheet/test/generate_pdf_usecase_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;
import 'dart:typed_data' as _i8;

import 'package:mockito/mockito.dart' as _i1;
import 'package:time_sheet/features/pointage/data/models/generated_pdf/generated_pdf.dart'
    as _i6;
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart'
    as _i5;
import 'package:time_sheet/features/pointage/domain/repositories/timesheet_repository.dart'
    as _i3;
import 'package:time_sheet/features/preference/domain/repositories/user_preference_repository.dart'
    as _i2;
import 'package:time_sheet/features/preference/domain/use_cases/get_signature_usecase.dart'
    as _i7;
import 'package:time_sheet/features/preference/domain/use_cases/get_user_preference_use_case.dart'
    as _i9;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeUserPreferencesRepository_0 extends _i1.SmartFake
    implements _i2.UserPreferencesRepository {
  _FakeUserPreferencesRepository_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [TimesheetRepository].
///
/// See the documentation for Mockito's code generation for more information.
class MockTimesheetRepository extends _i1.Mock
    implements _i3.TimesheetRepository {
  MockTimesheetRepository() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.Future<int> saveTimesheetEntry(_i5.TimesheetEntry? entry) =>
      (super.noSuchMethod(
        Invocation.method(
          #saveTimesheetEntry,
          [entry],
        ),
        returnValue: _i4.Future<int>.value(0),
      ) as _i4.Future<int>);

  @override
  _i4.Future<List<_i5.TimesheetEntry>> getTimesheetEntries() =>
      (super.noSuchMethod(
        Invocation.method(
          #getTimesheetEntries,
          [],
        ),
        returnValue:
            _i4.Future<List<_i5.TimesheetEntry>>.value(<_i5.TimesheetEntry>[]),
      ) as _i4.Future<List<_i5.TimesheetEntry>>);

  @override
  _i4.Future<void> deleteTimeSheet(int? id) => (super.noSuchMethod(
        Invocation.method(
          #deleteTimeSheet,
          [id],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<List<_i5.TimesheetEntry>> getTimesheetEntriesForWeek(
          int? weekNumber) =>
      (super.noSuchMethod(
        Invocation.method(
          #getTimesheetEntriesForWeek,
          [weekNumber],
        ),
        returnValue:
            _i4.Future<List<_i5.TimesheetEntry>>.value(<_i5.TimesheetEntry>[]),
      ) as _i4.Future<List<_i5.TimesheetEntry>>);

  @override
  _i4.Future<List<_i5.TimesheetEntry>> findEntriesFromMonthOf(
          int? monthNumber) =>
      (super.noSuchMethod(
        Invocation.method(
          #findEntriesFromMonthOf,
          [monthNumber],
        ),
        returnValue:
            _i4.Future<List<_i5.TimesheetEntry>>.value(<_i5.TimesheetEntry>[]),
      ) as _i4.Future<List<_i5.TimesheetEntry>>);

  @override
  _i4.Future<List<_i5.TimesheetEntry>> getTimesheetEntriesForMonth(
          int? monthNumber) =>
      (super.noSuchMethod(
        Invocation.method(
          #getTimesheetEntriesForMonth,
          [monthNumber],
        ),
        returnValue:
            _i4.Future<List<_i5.TimesheetEntry>>.value(<_i5.TimesheetEntry>[]),
      ) as _i4.Future<List<_i5.TimesheetEntry>>);

  @override
  _i4.Future<void> saveGeneratedPdf(_i6.GeneratedPdfModel? pdf) =>
      (super.noSuchMethod(
        Invocation.method(
          #saveGeneratedPdf,
          [pdf],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<List<_i6.GeneratedPdfModel>> getGeneratedPdfs() =>
      (super.noSuchMethod(
        Invocation.method(
          #getGeneratedPdfs,
          [],
        ),
        returnValue: _i4.Future<List<_i6.GeneratedPdfModel>>.value(
            <_i6.GeneratedPdfModel>[]),
      ) as _i4.Future<List<_i6.GeneratedPdfModel>>);

  @override
  _i4.Future<void> deleteGeneratedPdf(int? pdfId) => (super.noSuchMethod(
        Invocation.method(
          #deleteGeneratedPdf,
          [pdfId],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<_i5.TimesheetEntry?> getTimesheetEntryForDate(String? date) =>
      (super.noSuchMethod(
        Invocation.method(
          #getTimesheetEntryForDate,
          [date],
        ),
        returnValue: _i4.Future<_i5.TimesheetEntry?>.value(),
      ) as _i4.Future<_i5.TimesheetEntry?>);

  @override
  _i4.Future<_i5.TimesheetEntry?> getTimesheetEntry(String? formattedDate) =>
      (super.noSuchMethod(
        Invocation.method(
          #getTimesheetEntry,
          [formattedDate],
        ),
        returnValue: _i4.Future<_i5.TimesheetEntry?>.value(),
      ) as _i4.Future<_i5.TimesheetEntry?>);

  @override
  _i4.Future<_i5.TimesheetEntry?> getTimesheetEntryWhitFrenchFormat(
          String? formattedDate) =>
      (super.noSuchMethod(
        Invocation.method(
          #getTimesheetEntryWhitFrenchFormat,
          [formattedDate],
        ),
        returnValue: _i4.Future<_i5.TimesheetEntry?>.value(),
      ) as _i4.Future<_i5.TimesheetEntry?>);

  @override
  _i4.Future<int> getVacationDaysCount() => (super.noSuchMethod(
        Invocation.method(
          #getVacationDaysCount,
          [],
        ),
        returnValue: _i4.Future<int>.value(0),
      ) as _i4.Future<int>);
}

/// A class which mocks [GetSignatureUseCase].
///
/// See the documentation for Mockito's code generation for more information.
class MockGetSignatureUseCase extends _i1.Mock
    implements _i7.GetSignatureUseCase {
  MockGetSignatureUseCase() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i2.UserPreferencesRepository get repository => (super.noSuchMethod(
        Invocation.getter(#repository),
        returnValue: _FakeUserPreferencesRepository_0(
          this,
          Invocation.getter(#repository),
        ),
      ) as _i2.UserPreferencesRepository);

  @override
  _i4.Future<_i8.Uint8List?> execute() => (super.noSuchMethod(
        Invocation.method(
          #execute,
          [],
        ),
        returnValue: _i4.Future<_i8.Uint8List?>.value(),
      ) as _i4.Future<_i8.Uint8List?>);
}

/// A class which mocks [GetUserPreferenceUseCase].
///
/// See the documentation for Mockito's code generation for more information.
class MockGetUserPreferenceUseCase extends _i1.Mock
    implements _i9.GetUserPreferenceUseCase {
  MockGetUserPreferenceUseCase() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i2.UserPreferencesRepository get repository => (super.noSuchMethod(
        Invocation.getter(#repository),
        returnValue: _FakeUserPreferencesRepository_0(
          this,
          Invocation.getter(#repository),
        ),
      ) as _i2.UserPreferencesRepository);

  @override
  _i4.Future<String?> execute(String? key) => (super.noSuchMethod(
        Invocation.method(
          #execute,
          [key],
        ),
        returnValue: _i4.Future<String?>.value(),
      ) as _i4.Future<String?>);
}