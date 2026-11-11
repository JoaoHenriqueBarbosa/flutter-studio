import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/sample_contract.dart';

void main() {
  group('ContractDocument', () {
    // Verifies: NFR-MNT-006
    test('reads methods, events, schemas and errors', () {
      final document = sampleContract;

      expect(document.title, 'Sample');
      expect(document.version, '1.2.3');
      expect(document.binding, {'serviceName': 'Sample'});
      expect(document.methods.single.name, 'rename');
      expect(document.methods.single.errors, ['NotFound']);
      expect(document.methods.single.params.map((param) => param.isRequired), [
        true,
        false,
      ]);
      expect(document.events.single.name, 'renamed');
      expect(document.agentExtensionPrefix, 'ext.sample.agent');
      expect(document.agentExtensions.single.name, 'ping');
      expect(document.schemas.map((schema) => schema.name), ['Thing', 'Kind']);
      expect(document.schemas.last.enumValues, ['small', 'large']);
      expect(document.errors.single, (
        name: 'NotFound',
        code: -32001,
        data: 'The label.',
      ));
    });

    // Verifies: NFR-MNT-006
    test('refuses a method whose name breaks the convention', () {
      final source = sampleContractSource.replaceFirst(
        '"name": "rename"',
        '"name": "Rename"',
      );

      expect(() => ContractDocument.parse(source), throwsFormatException);
    });

    // Verifies: NFR-MNT-006
    test('refuses a property with no description', () {
      final source = sampleContractSource.replaceFirst(
        '"description": "The label.", ',
        '',
      );

      expect(() => ContractDocument.parse(source), throwsFormatException);
    });

    // Verifies: NFR-MNT-006
    test('refuses a method with no example', () {
      final source = sampleContractSource.replaceFirst(
        RegExp(r'"examples": \[.*\]\n'),
        '"examples": []\n',
      );

      expect(() => ContractDocument.parse(source), throwsFormatException);
    });

    // Verifies: NFR-MNT-006
    test('refuses a document with a missing section', () {
      expect(() => ContractDocument.parse('{}'), throwsFormatException);
    });
  });
}
