import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/sample_contract.dart';

void main() {
  group('ProtocolPackage', () {
    late Directory root;
    late ProtocolPackage package;

    setUp(() {
      root = Directory.systemTemp.createTempSync('protocol_package_test');
      File(path.join(root.path, 'studio.openrpc.json'))
          .writeAsStringSync(sampleContractSource);
      Directory(path.join(root.path, 'lib', 'src')).createSync(recursive: true);
      package = ProtocolPackage(root.path, const SystemProcessRunner());
    });

    tearDown(() => root.deleteSync(recursive: true));

    // Verifies: NFR-MNT-006
    test('generates formatted files that a check finds up to date', () async {
      await package.generate();

      final thing = File(
        path.join(root.path, 'lib', 'src', 'generated', 'thing.dart'),
      ).readAsStringSync();
      expect(thing, contains('const Thing({required this.label, this.kind'));
      expect(await package.findDifferences(), isEmpty);
    });

    // Verifies: NFR-MNT-006
    test('a check names the edited, the missing and the extra file', () async {
      await package.generate();
      final generated = path.join(root.path, 'lib', 'src', 'generated');
      File(path.join(generated, 'thing.dart')).writeAsStringSync('// Edited.');
      File(path.join(generated, 'kind.dart')).deleteSync();
      File(path.join(generated, 'stale.dart')).writeAsStringSync('// Stale.');

      expect(await package.findDifferences(), [
        'src/generated/kind.dart',
        'src/generated/stale.dart',
        'src/generated/thing.dart',
      ]);
    });

    // Verifies: NFR-MNT-006
    test('refuses an invalid contract', () async {
      File(path.join(root.path, 'studio.openrpc.json')).writeAsStringSync('{}');

      await expectLater(package.generate(), throwsFormatException);
    });
  });
}
