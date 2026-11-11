import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/studio_core.dart';

TextEdit _replace(
  ({int line, int character}) start,
  ({int line, int character}) end,
  String newText,
) => (range: (start: start, end: end), newText: newText);

void main() {
  // Verifies: FR-DOC-007
  group('TextDocument.applying', () {
    test('replaces only the text of the range', () {
      const document = TextDocument('a: .center,\nb: 1,\n', version: 1);

      final edited = document.applying([
        _replace((line: 0, character: 3), (line: 0, character: 10), '.end'),
      ]);

      expect(edited.text, 'a: .end,\nb: 1,\n');
      expect(edited.version, 2);
    });

    test('applies several edits against the original positions', () {
      const document = TextDocument('one two three', version: 4);

      final edited = document.applying([
        _replace((line: 0, character: 0), (line: 0, character: 3), '1'),
        _replace((line: 0, character: 8), (line: 0, character: 13), '3'),
      ]);

      expect(edited.text, '1 two 3');
      expect(edited.version, 5);
    });

    test('counts lines that end in CRLF and characters in UTF-16', () {
      const document = TextDocument('x = "😀";\r\ny = 1;\r\n', version: 1);

      final edited = document.applying([
        _replace((line: 0, character: 5), (line: 0, character: 7), 'ok'),
        _replace((line: 1, character: 4), (line: 1, character: 5), '2'),
      ]);

      expect(edited.text, 'x = "ok";\r\ny = 2;\r\n');
    });

    test('inserts at the end of the text', () {
      const document = TextDocument('a\n', version: 1);

      final edited = document.applying([
        _replace((line: 1, character: 0), (line: 1, character: 0), 'b\n'),
      ]);

      expect(edited.text, 'a\nb\n');
    });

    test('rejects a range outside the text', () {
      const document = TextDocument('a\n', version: 1);

      expect(
        () => document.applying([
          _replace((line: 5, character: 0), (line: 5, character: 1), 'x'),
        ]),
        throwsA(isA<InvalidEdit>()),
      );
    });

    test('rejects overlapping ranges', () {
      const document = TextDocument('abcdef', version: 1);

      expect(
        () => document.applying([
          _replace((line: 0, character: 0), (line: 0, character: 4), 'x'),
          _replace((line: 0, character: 2), (line: 0, character: 5), 'y'),
        ]),
        throwsA(isA<InvalidEdit>()),
      );
    });
  });
}
