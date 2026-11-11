import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/sample_contract.dart';

void main() {
  group('GenerateCommand', () {
    late Directory workspace;
    late StringBuffer output;
    late CommandRunner<int> runner;
    late String contractPath;

    setUp(() {
      workspace = Directory.systemTemp.createTempSync('generate_command_test');
      final packagePath = path.join(
        workspace.path,
        GenerateCommand.protocolPackagePath,
      );
      Directory(path.join(packagePath, 'lib', 'src'))
          .createSync(recursive: true);
      contractPath = path.join(packagePath, 'studio.openrpc.json');
      File(contractPath).writeAsStringSync(sampleContractSource);
      output = StringBuffer();
      runner = CommandRunner<int>('st', 'Test.')
        ..addCommand(GenerateCommand(const SystemProcessRunner(), output));
    });

    tearDown(() => workspace.deleteSync(recursive: true));

    Future<int?> run(List<String> arguments) =>
        runner.run(['generate', '--workspace', workspace.path, ...arguments]);

    // Verifies: NFR-MNT-006
    test('generates, and then a check succeeds', () async {
      expect(await run([]), 0);
      expect(await run(['--check']), 0);
      expect('$output', isEmpty);
    });

    // Verifies: NFR-MNT-006
    test('a check fails and names the stale files', () async {
      expect(await run(['--check']), 1);
      expect('$output', contains('src/generated/thing.dart'));
    });

    // Verifies: NFR-MNT-006
    test('fails on an invalid contract', () async {
      File(contractPath).writeAsStringSync('{}');

      expect(await run([]), 1);
      expect('$output', contains('FormatException'));
    });
  });
}
