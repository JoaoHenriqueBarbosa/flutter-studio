import 'package:args/command_runner.dart';
import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/fake_process_runner.dart';

void main() {
  // Verifies: NFR-MNT-005
  group('VerifyCommand', () {
    Future<(int?, String)> runVerify(Map<String, ToolRun> runs) async {
      final output = StringBuffer();
      final gate = QualityGate(
        [
          ProcessStep(
            FakeProcessRunner(runs),
            id: 'QG-01',
            invocations: const [
              ToolInvocation('dart', ['format']),
            ],
          ),
        ],
        requiredStepIds: const ['QG-01'],
      );
      final runner = CommandRunner<int>('st', 'Test runner.')
        ..addCommand(VerifyCommand(gate, output));
      return (await runner.run(['verify']), '$output');
    }

    test('exits with zero when every step approves', () async {
      final (exitCode, output) = await runVerify({
        'dart': const ToolRun(exitCode: 0, output: ''),
      });

      expect(exitCode, 0);
      expect(output, 'QG-01 passed\nQuality gate approved.\n');
    });

    test('exits with one and shows the detail when a step fails', () async {
      final (exitCode, output) = await runVerify({
        'dart': const ToolRun(exitCode: 1, output: 'Changed lib/a.dart\n'),
      });

      expect(exitCode, 1);
      expect(
        output,
        'QG-01 failed\nChanged lib/a.dart\nQuality gate rejected.\n',
      );
    });

    test('exits with one when a step cannot run', () async {
      final (exitCode, output) = await runVerify(const {});

      expect(exitCode, 1);
      expect(
        output,
        'QG-01 notRun\ndart is not installed.\nQuality gate rejected.\n',
      );
    });
  });
}
