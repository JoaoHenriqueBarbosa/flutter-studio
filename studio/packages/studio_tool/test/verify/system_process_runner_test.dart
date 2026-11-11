import 'dart:io';

import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

void main() {
  // Verifies: NFR-MNT-005
  group('SystemProcessRunner', () {
    const runner = SystemProcessRunner();

    test('completes with the exit code and the output of the tool', () async {
      final run = await runner.run(
        const ToolInvocation('dart', ['--version']),
        workingDirectory: Directory.current,
      );

      expect(run?.exitCode, 0);
      expect(run?.output, contains('Dart SDK version'));
    });

    test('completes with null when the executable does not exist', () async {
      final run = await runner.run(
        const ToolInvocation('executable-that-does-not-exist', []),
        workingDirectory: Directory.current,
      );

      expect(run, isNull);
    });
  });
}
