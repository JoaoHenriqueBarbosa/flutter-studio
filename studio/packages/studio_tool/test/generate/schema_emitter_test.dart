import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/sample_contract.dart';

void main() {
  group('SchemaEmitter', () {
    const emitter = SchemaEmitter();

    // Verifies: NFR-MNT-006
    test('writes a value class with the description as documentation', () {
      final source = emitter.emit(sampleContract.schemas.first);

      expect(source, startsWith(generatedHeader));
      expect(source, contains("import 'kind.dart';"));
      expect(
        source,
        contains('/// A thing with a label.\nfinal class Thing {'),
      );
      expect(source, contains('  /// The kind.\n  final Kind? kind;'));
      expect(source, contains('required this.label, this.kind, this.tags,'));
      expect(source, contains("'tags': ?tags,"));
    });

    // Verifies: NFR-MNT-006
    test('writes an enum with one value for each wire value', () {
      final source = emitter.emit(sampleContract.schemas.last);

      expect(source, contains('enum Kind {'));
      expect(source, contains('  /// The value `small`.\n  small,'));
      expect(source, contains('String toJson() => name;'));
    });
  });
}
