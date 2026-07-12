import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/preference/data/utils/weekend_days_db_codec.dart';

void main() {
  group('WeekendDaysDbCodec', () {
    group('encode', () {
      test('should produce a PostgreSQL array literal', () {
        expect(WeekendDaysDbCodec.encode([6, 7]), '{6,7}');
        expect(WeekendDaysDbCodec.encode([5]), '{5}');
        expect(WeekendDaysDbCodec.encode([]), '{}');
      });
    });

    group('decode', () {
      test('should round-trip a locally written value (write then read)', () {
        expect(
          WeekendDaysDbCodec.decode(WeekendDaysDbCodec.encode([6, 7])),
          [6, 7],
        );
      });

      test('should decode the PostgreSQL literal format {6,7}', () {
        expect(WeekendDaysDbCodec.decode('{6,7}'), [6, 7]);
        expect(WeekendDaysDbCodec.decode('{ 6 , 7 }'), [6, 7]);
        expect(WeekendDaysDbCodec.decode('{}'), <int>[]);
      });

      test('should decode the JSON format [6,7] (PowerSync download)', () {
        expect(WeekendDaysDbCodec.decode('[6,7]'), [6, 7]);
        expect(WeekendDaysDbCodec.decode('[5]'), [5]);
        expect(WeekendDaysDbCodec.decode('[]'), <int>[]);
      });

      test('should return null for missing or unreadable values', () {
        expect(WeekendDaysDbCodec.decode(null), isNull);
        expect(WeekendDaysDbCodec.decode(''), isNull);
        expect(WeekendDaysDbCodec.decode('not-a-list'), isNull);
        expect(WeekendDaysDbCodec.decode('{6,x}'), isNull);
      });
    });
  });
}
