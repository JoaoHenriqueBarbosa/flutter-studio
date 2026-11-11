import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/structure_workspace.dart';

void main() {
  group('StructureStep', () {
    late Directory sandbox;
    const step = StructureStep();

    setUp(() => sandbox = Directory.systemTemp.createTempSync('structure'));

    tearDown(() => sandbox.deleteSync(recursive: true));

    // Verifies: NFR-MNT-005
    test('passes a workspace with the structure of the standard', () async {
      final workspace = createStructureWorkspace(
        sandbox,
        packages: {
          'studio_protocol': [],
          'studio_core': ['studio_protocol'],
          'studio_shell': ['studio_core', 'devtools_app'],
        },
      );

      expect(step.id, 'QG-08');
      expect(await step.run(workspace), const StepOutcome(StepStatus.passed));
    });

    // Verifies: NFR-MNT-005
    test('fails when the version of Flutter is not pinned', () async {
      final workspace = createStructureWorkspace(
        sandbox,
        packages: {'studio_protocol': []},
      );
      File(path.join(workspace.path, 'flutter-version.txt')).deleteSync();

      final outcome = await step.run(workspace);

      expect(
        outcome.detail,
        'The workspace does not pin the version of Flutter.',
      );
    });

    // Verifies: NFR-MNT-005
    test('does not run where there is no workspace', () async {
      expect((await step.run(sandbox)).status, StepStatus.notRun);
    });
  });
}
