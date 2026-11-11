import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/trace_workspace.dart';

void main() {
  group('TraceCommand', () {
    late Directory sandbox;
    late StringBuffer output;
    late CommandRunner<int> runner;

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('trace_command');
      output = StringBuffer();
      runner = CommandRunner<int>('st', 'Test.')
        ..addCommand(TraceCommand(output));
    });

    tearDown(() => sandbox.deleteSync(recursive: true));

    Future<int?> run(String testSource, List<String> arguments) {
      final workspace = createTraceWorkspace(sandbox, testSource: testSource);
      return runner.run(['trace', '--workspace', workspace.path, ...arguments]);
    }

    // Verifies: NFR-MNT-005
    test('prints the matrix and succeeds without the check', () async {
      expect(await run('// Verifies: FR-DOC-001', []), 0);
      expect('$output', contains('FR-DOC-001 F0 1'));
      expect('$output', contains('Without test up to F1: FR-DOC-002'));
    });

    // Verifies: NFR-MNT-005
    test('the check fails on a gap and passes without one', () async {
      expect(await run('// Verifies: FR-DOC-001', ['--check']), 1);
      sandbox.listSync().forEach(
        (entity) => entity.deleteSync(recursive: true),
      );
      expect(await run('// Verifies: FR-DOC-001, FR-DOC-002', ['--check']), 0);
    });

    // Verifies: NFR-MNT-005
    test('fails where there is no workspace', () async {
      expect(await runner.run(['trace', '--workspace', sandbox.path]), 1);
    });
  });
}
