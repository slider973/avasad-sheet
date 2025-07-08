import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/domain/mapper/generated_pdf_mapper.dart';
import 'package:time_sheet/features/pointage/domain/entities/generated_pdf.dart';
import 'package:time_sheet/features/pointage/data/models/generated_pdf/generated_pdf.dart';

void main() {
  group('GeneratedPdfMapper Tests - Clean Architecture', () {
    test('should map from model to entity correctly', () {
      // Arrange
      final model = GeneratedPdfModel(
        fileName: 'test.pdf',
        filePath: '/path/to/test.pdf',
        generatedDate: DateTime(2024, 1, 1),
      );
      model.id = 1;

      // Act
      final entity = GeneratedPdfMapper.fromModel(model);

      // Assert
      expect(entity.id, equals(1));
      expect(entity.fileName, equals('test.pdf'));
      expect(entity.filePath, equals('/path/to/test.pdf'));
      expect(entity.generatedDate, equals(DateTime(2024, 1, 1)));
    });

    test('should map from entity to model correctly', () {
      // Arrange
      final entity = GeneratedPdf(
        id: 1,
        fileName: 'test.pdf',
        filePath: '/path/to/test.pdf',
        generatedDate: DateTime(2024, 1, 1),
      );

      // Act
      final model = GeneratedPdfMapper.toModel(entity);

      // Assert
      expect(model.id, equals(1));
      expect(model.fileName, equals('test.pdf'));
      expect(model.filePath, equals('/path/to/test.pdf'));
      expect(model.generatedDate, equals(DateTime(2024, 1, 1)));
    });

    test('should map entity without id to model correctly', () {
      // Arrange
      final entity = GeneratedPdf(
        fileName: 'test.pdf',
        filePath: '/path/to/test.pdf',
        generatedDate: DateTime(2024, 1, 1),
      );

      // Act
      final model = GeneratedPdfMapper.toModel(entity);

      // Assert
      expect(model.id, equals(0)); // Default value when id is null
      expect(model.fileName, equals('test.pdf'));
      expect(model.filePath, equals('/path/to/test.pdf'));
      expect(model.generatedDate, equals(DateTime(2024, 1, 1)));
    });

    test('should map list of models to entities correctly', () {
      // Arrange
      final model1 = GeneratedPdfModel(
        fileName: 'test1.pdf',
        filePath: '/path/to/test1.pdf',
        generatedDate: DateTime(2024, 1, 1),
      );
      model1.id = 1;

      final model2 = GeneratedPdfModel(
        fileName: 'test2.pdf',
        filePath: '/path/to/test2.pdf',
        generatedDate: DateTime(2024, 1, 2),
      );
      model2.id = 2;

      final models = [model1, model2];

      // Act
      final entities = GeneratedPdfMapper.fromModelList(models);

      // Assert
      expect(entities.length, equals(2));
      expect(entities[0].id, equals(1));
      expect(entities[0].fileName, equals('test1.pdf'));
      expect(entities[1].id, equals(2));
      expect(entities[1].fileName, equals('test2.pdf'));
    });

    test('should map list of entities to models correctly', () {
      // Arrange
      final entities = [
        GeneratedPdf(
          id: 1,
          fileName: 'test1.pdf',
          filePath: '/path/to/test1.pdf',
          generatedDate: DateTime(2024, 1, 1),
        ),
        GeneratedPdf(
          id: 2,
          fileName: 'test2.pdf',
          filePath: '/path/to/test2.pdf',
          generatedDate: DateTime(2024, 1, 2),
        ),
      ];

      // Act
      final models = GeneratedPdfMapper.toModelList(entities);

      // Assert
      expect(models.length, equals(2));
      expect(models[0].id, equals(1));
      expect(models[0].fileName, equals('test1.pdf'));
      expect(models[1].id, equals(2));
      expect(models[1].fileName, equals('test2.pdf'));
    });
  });
}