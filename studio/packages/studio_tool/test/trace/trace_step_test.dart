import 'dart:io';

import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/trace_workspace.dart';

void main() {
  group('TraceStep', () {
    late Directory sandbox;
    const step = TraceStep();

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('trace_step');
    });

    tearDown(() => sandbox.deleteSync(recursive: true));

    // Verifies: NFR-MNT-005
    test('passes when the trace is complete', () async {
      final workspace = createTraceWorkspace(
        sandbox,
        testSource: '// Verifies: FR-DOC-001, FR-DOC-002',
      );

      expect(step.id, 'QG-12');
      expect(await step.run(workspace), const StepOutcome(StepStatus.passed));
    });

    // Verifies: NFR-MNT-005
    test('fails and names what is missing', () async {
      final workspace = createTraceWorkspace(
        sandbox,
        testSource: '// Verifies: FR-XYZ-999',
      );

      final outcome = await step.run(workspace);

      expect(outcome.status, StepStatus.failed);
      expect(outcome.detail, contains('Unknown identifier FR-XYZ-999'));
      expect(outcome.detail, contains('FR-DOC-001, FR-DOC-002'));
    });

    // Verifies: NFR-MNT-005
    test('does not run where there is no workspace', () async {
      expect((await step.run(sandbox)).status, StepStatus.notRun);
    });
  });
}
