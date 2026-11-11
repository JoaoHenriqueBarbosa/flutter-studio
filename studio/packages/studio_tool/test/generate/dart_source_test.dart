import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

void main() {
  // Verifies: NFR-MNT-006
  test('snakeCase turns a type name into a file name', () {
    expect(snakeCase('TextDocumentEdit'), 'text_document_edit');
    expect(snakeCase('getVersion'), 'get_version');
  });

  // Verifies: NFR-MNT-006
  test('lowerFirst lowers only the first letter', () {
    expect(lowerFirst('StaleDocument'), 'staleDocument');
  });

  // Verifies: NFR-MNT-006
  test('docComment wraps the text and separates paragraphs', () {
    final comment = docComment('${'word ' * 20}end\nSecond.', indent: '  ');
    final lines = comment.split('\n');

    expect(lines.every((line) => line.length <= 80), isTrue);
    expect(lines.every((line) => line.startsWith('  ///')), isTrue);
    expect(lines.sublist(lines.length - 2), ['  ///', '  /// Second.']);
  });

  // Verifies: NFR-MNT-006
  test('importDirectives sorts and removes repeats', () {
    expect(
      importDirectives(['b.dart', '../a.dart', 'b.dart']),
      "import '../a.dart';\nimport 'b.dart';",
    );
  });

  // Verifies: NFR-MNT-006
  test('jsonEntry leaves an absent optional field out of the map', () {
    const text = PrimitiveType('String');
    const thing = ReferenceType('Thing');

    expect(
      jsonEntry((name: 'a', description: '', type: text, isRequired: true)),
      "'a': a,",
    );
    expect(
      jsonEntry((name: 'a', description: '', type: text, isRequired: false)),
      "'a': ?a,",
    );
    expect(
      jsonEntry((name: 'a', description: '', type: thing, isRequired: false)),
      "if (a case final a?) 'a': a.toJson(),",
    );
  });
}
