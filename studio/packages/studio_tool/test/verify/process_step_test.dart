import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/fake_process_runner.dart';

void main() {
  // Verifies: NFR-MNT-005
  group('ProcessStep', () {
    late Directory workspace;

    setUp(() {
      workspace = Directory.systemTemp.createTempSync('process_step_test');
    });

    tearDown(() {
      workspace.deleteSync(recursive: true);
    });

    test('passes when every tool exits with zero', () async {
      final runner = FakeProcessRunner({
        'dart': const ToolRun(exitCode: 0, output: ''),
      });
      final step = ProcessStep(
        runner,
        id: 'QG-01',
        invocations: const [
          ToolInvocation('dart', ['format']),
          ToolInvocation('dart', ['analyze']),
        ],
      );

      final outcome = await step.run(workspace);

      expect(outcome, const StepOutcome(StepStatus.passed));
      expect(runner.commandLines, ['dart format', 'dart analyze']);
    });

    test('fails with the output of the first tool that fails', () async {
      final runner = FakeProcessRunner({
        'dart': const ToolRun(exitCode: 1, output: 'Changed lib/a.dart'),
      });
      final step = ProcessStep(
        runner,
        id: 'QG-01',
        invocations: const [
          ToolInvocation('dart', ['format']),
          ToolInvocation('dart', ['analyze']),
        ],
      );

      final outcome = await step.run(workspace);

      expect(
        outcome,
        const StepOutcome(StepStatus.failed, detail: 'Changed lib/a.dart'),
      );
      expect(runner.commandLines, ['dart format']);
    });

    test('does not run when the tool is not installed', () async {
      final step = ProcessStep(
        FakeProcessRunner(const {}),
        id: 'QG-03',
        invocations: const [
          ToolInvocation('dcm', ['analyze']),
        ],
      );

      final outcome = await step.run(workspace);

      expect(
        outcome,
        const StepOutcome(StepStatus.notRun, detail: 'dcm is not installed.'),
      );
    });

    test('does not apply to a workspace without the required file', () async {
      final runner = FakeProcessRunner(const {});
      final step = ProcessStep(
        runner,
        id: 'QG-04',
        requiredFile: 'Cargo.toml',
        invocations: const [
          ToolInvocation('cargo', ['fmt']),
        ],
      );

      final outcome = await step.run(workspace);

      expect(
        outcome,
        const StepOutcome(
          StepStatus.notApplicable,
          detail: 'The workspace has no Cargo.toml.',
        ),
      );
      expect(runner.commandLines, isEmpty);
    });

    test('runs on a workspace that has the required file', () async {
      File(path.join(workspace.path, 'Cargo.toml')).createSync();
      final step = ProcessStep(
        FakeProcessRunner({'cargo': const ToolRun(exitCode: 0, output: '')}),
        id: 'QG-04',
        requiredFile: 'Cargo.toml',
        invocations: const [
          ToolInvocation('cargo', ['fmt']),
        ],
      );

      final outcome = await step.run(workspace);

      expect(outcome, const StepOutcome(StepStatus.passed));
    });
  });
}
