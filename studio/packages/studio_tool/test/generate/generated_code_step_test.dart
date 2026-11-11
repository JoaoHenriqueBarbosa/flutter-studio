import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/sample_contract.dart';

void main() {
  group('GeneratedCodeStep', () {
    late Directory workspace;
    late String packagePath;
    const step = GeneratedCodeStep(SystemProcessRunner());

    setUp(() {
      workspace = Directory.systemTemp.createTempSync('generated_code_step');
      packagePath = path.join(
        workspace.path,
        GenerateCommand.protocolPackagePath,
      );
      Directory(path.join(packagePath, 'lib', 'src'))
          .createSync(recursive: true);
      File(path.join(packagePath, 'studio.openrpc.json'))
          .writeAsStringSync(sampleContractSource);
    });

    tearDown(() => workspace.deleteSync(recursive: true));

    // Verifies: NFR-MNT-005, NFR-MNT-006
    test('passes when the generated code is up to date', () async {
      await ProtocolPackage(
        packagePath,
        const SystemProcessRunner(),
      ).generate();

      expect(step.id, 'QG-09');
      expect(await step.run(workspace), const StepOutcome(StepStatus.passed));
    });

    // Verifies: NFR-MNT-005, NFR-MNT-006
    test('fails and names the files when the code is stale', () async {
      final outcome = await step.run(workspace);

      expect(outcome.status, StepStatus.failed);
      expect(outcome.detail, contains('src/generated/thing.dart'));
    });

    // Verifies: NFR-MNT-005
    test('fails when the contract is invalid', () async {
      File(path.join(packagePath, 'studio.openrpc.json'))
          .writeAsStringSync('{}');

      expect((await step.run(workspace)).status, StepStatus.failed);
    });

    // Verifies: NFR-MNT-005
    test('does not run when the workspace has no protocol package', () async {
      final empty = Directory.systemTemp.createTempSync('empty_workspace');
      addTearDown(() => empty.deleteSync(recursive: true));

      expect((await step.run(empty)).status, StepStatus.notRun);
    });
  });
}
