import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/fake_process_runner.dart';
import '../support/sample_contract.dart';

void main() {
  group('DocumentationSet', () {
    late Directory workspace;
    const clean = ToolRun(
      exitCode: 0,
      output: 'Found 0 warnings and 0 errors.\n',
    );
    const withWarning = ToolRun(
      exitCode: 0,
      output: '  warning: unresolved doc reference [Foo]\nFound 1 warnings\n',
    );

    setUp(() {
      workspace = Directory.systemTemp.createTempSync('documentation_set');
      final protocol = path.join(
        workspace.path,
        GenerateCommand.protocolPackagePath,
      );
      File(path.join(protocol, 'pubspec.yaml')).createSync(recursive: true);
      File(path.join(protocol, 'studio.openrpc.json'))
          .writeAsStringSync(sampleContractSource);
      // A directory that is not a package is left alone.
      Directory(path.join(workspace.path, 'packages', 'notes')).createSync();
    });

    tearDown(() => workspace.deleteSync(recursive: true));

    // Verifies: NFR-MNT-007
    test('writes the service reference and documents each package', () async {
      final runner = FakeProcessRunner({'dart': clean});

      final problems = await DocumentationSet(workspace, runner).generate();

      expect(problems, isEmpty);
      expect(runner.commandLines.single, startsWith('dart doc --output '));
      expect(
        File(path.join(workspace.path, 'doc', 'api', 'studio-service.md'))
            .readAsStringSync(),
        contains('# Sample service 1.2.3'),
      );
    });

    // Verifies: NFR-MNT-007
    test('reports the package whose reference has a warning', () async {
      final problems = await DocumentationSet(
        workspace,
        FakeProcessRunner({'dart': withWarning}),
      ).generate();

      expect(problems.single, startsWith('studio_protocol:\n  warning: '));
    });

    // Verifies: NFR-MNT-005, NFR-MNT-007
    test('the step of the gate passes, fails or does not run', () async {
      final passing = DocumentationStep(FakeProcessRunner({'dart': clean}));
      final failing = DocumentationStep(
        FakeProcessRunner({'dart': withWarning}),
      );
      final empty = Directory.systemTemp.createTempSync('no_workspace');
      addTearDown(() => empty.deleteSync(recursive: true));

      expect(passing.id, 'QG-11');
      expect((await passing.run(workspace)).status, StepStatus.passed);
      expect((await failing.run(workspace)).status, StepStatus.failed);
      expect((await passing.run(empty)).status, StepStatus.notRun);
    });

    // Verifies: NFR-MNT-007
    test('the command exits with one when there is a problem', () async {
      Future<int?> run(ToolRun answer) {
        final runner = CommandRunner<int>('st', 'Test.')
          ..addCommand(
            DocsCommand(FakeProcessRunner({'dart': answer}), StringBuffer()),
          );
        return runner.run(['docs', '--workspace', workspace.path]);
      }

      expect(await run(clean), 0);
      expect(await run(withWarning), 1);
    });
  });
}
