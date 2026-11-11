import 'dart:io';

import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/trace_workspace.dart';

void main() {
  group('TestTrace', () {
    late Directory sandbox;

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('test_trace');
    });

    tearDown(() => sandbox.deleteSync(recursive: true));

    // Verifies: NFR-MNT-005
    test('reads the identifiers of each comment, with its next lines', () {
      final workspace = createTraceWorkspace(
        sandbox,
        testSource: '''
// Verifies: FR-DOC-001, ADR-0004,
// FR-DOC-002
test('a', () {});

    // Verifies: FR-DOC-001
    // Not part of the marker: FR-CNV-001 is only mentioned.
''',
      );

      final trace = TestTrace.read(workspace);

      expect(trace.testsByIdentifier, {
        'FR-DOC-001': {'packages/core/test/store_test.dart'},
        'ADR-0004': {'packages/core/test/store_test.dart'},
        'FR-DOC-002': {'packages/core/test/store_test.dart'},
      });
    });
  });
}
