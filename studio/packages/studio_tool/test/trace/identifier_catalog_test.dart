import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/trace_workspace.dart';

void main() {
  group('IdentifierCatalog', () {
    late Directory sandbox;
    late IdentifierCatalog catalog;

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('identifier_catalog');
      createTraceWorkspace(sandbox, testSource: '');
      catalog = IdentifierCatalog.read(
        Directory(path.join(sandbox.path, 'docs')),
      );
    });

    tearDown(() => sandbox.deleteSync(recursive: true));

    // Verifies: NFR-MNT-005
    test('reads the identifiers that open a table row', () {
      expect(catalog.identifiers, {
        'FR-DOC-001',
        'FR-DOC-002',
        'FR-CNV-001',
        'IR-006',
        'DC-01',
        'ADR-0004',
      });
    });

    // Verifies: NFR-MNT-005
    test('reads the increment and the method of each requirement', () {
      expect(catalog.requirements, [
        (id: 'FR-DOC-001', increment: 'F0', isTested: true),
        (id: 'FR-DOC-002', increment: 'F1', isTested: true),
        (id: 'FR-CNV-001', increment: 'F2', isTested: true),
        (id: 'IR-006', increment: 'F0', isTested: false),
      ]);
    });
  });
}
