import 'dart:io';

import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/fake_process_runner.dart';
import '../support/source_workspace.dart';

void main() {
  group('MarkerStep', () {
    late Directory sandbox;
    const cleanLog = ToolRun(
      exitCode: 0,
      output: 'abc1234 Cria o pacote\n\x00',
    );

    setUp(() => sandbox = Directory.systemTemp.createTempSync('marker_step'));

    tearDown(() => sandbox.deleteSync(recursive: true));

    Future<StepOutcome> run(
      Map<String, String> sources, {
      ToolRun log = cleanLog,
      bool hasLicenseHeader = true,
    }) => MarkerStep(FakeProcessRunner({'git': log})).run(
      createSourceWorkspace(
        sandbox,
        sources: sources,
        hasLicenseHeader: hasLicenseHeader,
      ),
    );

    // Verifies: NFR-MNT-005
    test('passes clean code with clean commits', () async {
      final outcome = await run({
        'lib/a.dart':
            '// TO@DO(john): finish this, https://example.com/issues/1.\n'
            'final a = 1;\n',
      });

      expect(outcome, const StepOutcome(StepStatus.passed));
    });

    // Verifies: NFR-MNT-005
    test('fails the markers and the leftovers that may not stay', () async {
      final outcome = await run({
        'lib/a.dart':
            '// TO@DO: later\n// FIX@ME broken\nvoid f() => pri@nt(1);\n',
        'test/a_test.dart': "test('x', () {}, sk@ip: true);\n",
        'lib/b.dart': 'Never g() => throw Unimplemented@Error();\n',
      });

      expect(outcome.status, StepStatus.failed);
      expect(outcome.detail, '''
packages/core/lib/a.dart:1 has a marker of pending work without owner and issue.
packages/core/lib/a.dart:2 uses a marker that is not allowed.
packages/core/lib/a.dart:3 prints.
packages/core/lib/b.dart:1 has an unimplemented path.
packages/core/test/a_test.dart:1 skips a test.''');
    });

    // Verifies: NFR-MNT-005
    test('fails a commit that attributes the work to a tool', () async {
      final outcome = await run(
        {'lib/a.dart': 'final a = 1;\n'},
        log: const ToolRun(
          exitCode: 0,
          output:
              'abc1234 Cria o pacote\n\x00'
              'def5678 Corrige\n\nCo-Authored-By: Some Tool\n\x00',
        ),
      );

      expect(outcome.detail, 'Commit def5678 attributes the work to a tool.');
    });

    // Verifies: NFR-MNT-005
    test('does not approve while the license header has no text', () async {
      final outcome = await run({
        'lib/a.dart': 'final a = 1;\n',
      }, hasLicenseHeader: false);

      expect(outcome.status, StepStatus.notRun);
    });
  });
}
