import 'dart:io';

import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/trace_workspace.dart';

void main() {
  group('TraceReport', () {
    late Directory sandbox;

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('trace_report');
    });

    tearDown(() => sandbox.deleteSync(recursive: true));

    TraceReport reportOf(String testSource, {String increment = 'F1'}) =>
        const WorkspaceTrace().read(
          createTraceWorkspace(
            sandbox,
            testSource: testSource,
            currentIncrement: increment,
          ),
        );

    // Verifies: NFR-MNT-005
    test('is complete when every requirement of the increment is tested', () {
      final report = reportOf('// Verifies: FR-DOC-001, FR-DOC-002');

      expect(report.isComplete, isTrue);
      expect(report.problems, isEmpty);
      expect(report.describe(), '''
FR-DOC-001 F0 1
FR-DOC-002 F1 1
FR-CNV-001 F2 0
IR-006 F0 0''');
    });

    // Verifies: NFR-MNT-005
    test('names the requirement of the increment that has no test', () {
      final report = reportOf('// Verifies: FR-DOC-001');

      expect(report.untestedRequirements, ['FR-DOC-002']);
      expect(report.problems, ['Without test up to F1: FR-DOC-002']);
    });

    // Verifies: NFR-MNT-005
    test('asks for the tests of a later increment only when it comes', () {
      final report = reportOf(
        '// Verifies: FR-DOC-001, FR-DOC-002',
        increment: 'F2',
      );

      expect(report.untestedRequirements, ['FR-CNV-001']);
    });

    // Verifies: NFR-MNT-005
    test('names the identifier that no document defines', () {
      final report = reportOf(
        '// Verifies: FR-DOC-001, FR-DOC-002, FR-XYZ-999',
      );

      expect(report.isComplete, isFalse);
      expect(report.unknownIdentifiers, {
        'FR-XYZ-999': {'packages/core/test/store_test.dart'},
      });
    });
  });
}
