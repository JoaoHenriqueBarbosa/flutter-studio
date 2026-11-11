import 'dart:io';

import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/fake_process_runner.dart';

void main() {
  // Verifies: NFR-MNT-005
  group('QualityGate', () {
    test('reports one outcome for each required step, in order', () async {
      final runner = FakeProcessRunner({
        'dart': const ToolRun(exitCode: 0, output: ''),
      });
      final gate = QualityGate(
        [
          ProcessStep(
            runner,
            id: 'QG-02',
            invocations: const [
              ToolInvocation('dart', ['analyze']),
            ],
          ),
        ],
        requiredStepIds: const ['QG-01', 'QG-02'],
      );

      final outcomes = await gate.run(Directory.current);

      expect(outcomes.keys, ['QG-01', 'QG-02']);
      expect(outcomes['QG-02'], const StepOutcome(StepStatus.passed));
    });

    test('reports a required step that is not built as not run', () async {
      const gate = QualityGate([], requiredStepIds: ['QG-09']);

      final outcomes = await gate.run(Directory.current);

      expect(
        outcomes['QG-09'],
        const StepOutcome(
          StepStatus.notRun,
          detail: 'No step is registered for this identifier.',
        ),
      );
    });
  });
}
