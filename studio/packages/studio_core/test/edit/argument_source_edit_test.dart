import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/studio_core.dart';

/// Returns [source] after the removal of the argument whose value is the
/// first occurrence of [value].
String _without(String source, String value) {
  final document = TextDocument(source, version: 1);
  final start = source.indexOf(value);
  final edit = ArgumentSourceEdit(document).removingArgument((
    start: document.positionAt(start),
    end: document.positionAt(start + value.length),
  ));
  return document.applying([edit]).text;
}

void main() {
  group('ArgumentSourceEdit', () {
    // Verifies: FR-PRP-008, FR-DOC-007
    test('removes the line of an argument that is alone on it', () {
      const source = '''
Column(
  mainAxisAlignment: .center,
  children: [],
)
''';

      expect(_without(source, '.center'), '''
Column(
  children: [],
)
''');
    });

    // Verifies: FR-PRP-008
    test('removes an argument from the middle of a line', () {
      expect(
        _without("Text('a', maxLines: 2, softWrap: true)", '2'),
        "Text('a', softWrap: true)",
      );
    });

    // Verifies: FR-PRP-008
    test('removes the last argument with the comma before it', () {
      expect(
        _without("Text('a', maxLines: 2, softWrap: true)", 'true'),
        "Text('a', maxLines: 2)",
      );
      expect(
        _without('Padding(\n  padding: p,\n  child: kid\n)', 'kid'),
        'Padding(\n  padding: p\n)',
      );
    });

    // Verifies: FR-PRP-008
    test('removes the only argument', () {
      expect(_without('SizedBox(width: 10)', '10'), 'SizedBox()');
    });

    // Verifies: FR-PRP-008
    test('refuses to remove a positional argument', () {
      expect(
        () => _without("Text('a', maxLines: 2)", "'a'"),
        throwsA(isA<UnsupportedEdit>()),
      );
    });

    // Verifies: FR-PRP-007
    test('puts another expression in place of the value', () {
      const document = TextDocument('Text(style: a)', version: 1);
      const range = (
        start: (line: 0, character: 12),
        end: (line: 0, character: 13),
      );

      final edit = const ArgumentSourceEdit(document)
          .replacingValue(range, 'theme.title');

      expect(document.applying([edit]).text, 'Text(style: theme.title)');
    });
  });
}
