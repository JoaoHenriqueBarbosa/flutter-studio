import 'package:studio_protocol/studio_protocol.dart';
import 'package:test/test.dart';

void main() {
  group('asJson', () {
    // Verifies: NFR-MNT-006
    test('returns a value of the expected type', () {
      expect(asJson<int>(3), 3);
    });

    // Verifies: NFR-MNT-006
    test('reports a value of another type as a malformed message', () {
      expect(() => asJson<int>('3'), throwsFormatException);
      expect(() => asJson<String>(null), throwsFormatException);
    });
  });

  group('jsonEquals', () {
    // Verifies: NFR-MNT-006
    test('compares lists and maps in depth', () {
      final left = {
        'edits': [
          {'newText': 'a'},
        ],
      };
      final right = {
        'edits': [
          {'newText': 'a'},
        ],
      };

      expect(jsonEquals(left, right), isTrue);
      expect(jsonHash(left), jsonHash(right));
    });

    // Verifies: NFR-MNT-006
    test('tells apart values that differ in a nested field', () {
      expect(
        jsonEquals(
          {
            'edits': ['a'],
          },
          {
            'edits': ['b'],
          },
        ),
        isFalse,
      );
      expect(jsonEquals({'a': 1}, {'b': 1}), isFalse);
    });
  });
}
