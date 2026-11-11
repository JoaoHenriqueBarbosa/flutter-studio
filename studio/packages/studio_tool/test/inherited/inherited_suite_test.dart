import 'dart:io';

import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/fake_process_runner.dart';

void main() {
  group('InheritedSuite', () {
    // Verifies: NFR-MNT-004
    test('runs the tests of each inherited package', () async {
      const passed = ToolRun(exitCode: 0, output: 'All tests passed!');
      final runner = FakeProcessRunner({
        '/repo/tool/flutter-sdk/bin/flutter': passed,
        '/repo/tool/flutter-sdk/bin/dart': passed,
      });

      final problems = await InheritedSuite(
        '/repo',
        runner,
        searchPath: '/bin',
      ).run();

      expect(problems, isEmpty);
      expect(runner.commandLines, hasLength(InheritedSuite.testTools.length));
      expect(runner.commandLines.first, endsWith('flutter test'));
      expect(runner.commandLines.last, endsWith('dart test'));
    });

    // Verifies: NFR-MNT-004
    test('names the package whose tests fail or cannot run', () async {
      final failing = FakeProcessRunner({
        '/repo/tool/flutter-sdk/bin/flutter': const ToolRun(
          exitCode: 1,
          output: 'a\nb\nSome tests failed.\n',
        ),
      });

      final failed = await InheritedSuite(
        '/repo',
        failing,
        searchPath: '/bin',
      ).run();
      final missing = await InheritedSuite(
        '/repo',
        FakeProcessRunner({}),
        searchPath: '/bin',
      ).run();

      expect(failed.first, 'packages/devtools_app: Some tests failed. | b | a');
      expect(
        missing.first,
        'packages/devtools_app: the candidate SDK is not installed.',
      );
    });

    // Verifies: NFR-MNT-004
    test('the inherited tests pass with the patches of Studio', () async {
      // From the package, the repository is three directories up.
      final problems = await InheritedSuite(
        '../../..',
        const SystemProcessRunner(),
        searchPath: Platform.environment['PATH'] ?? '',
      ).run();

      expect(problems, isEmpty);
    }, tags: 'inherited');
  });
}
