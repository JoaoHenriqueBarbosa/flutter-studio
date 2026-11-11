import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:studio_core/studio_core.dart';
import 'package:studio_shell/studio_shell.dart';

import '../support/workbench_fixture.dart';

void main() {
  group('WorkbenchController', () {
    late Directory sandbox;
    late InheritedDevTools devTools;
    late WorkbenchController controller;

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('workbench_test');
      devTools = createDisconnectedDevTools();
      controller = createWorkbenchController(devTools);
    });

    tearDown(() {
      controller.dispose();
      devTools.dispose();
      sandbox.deleteSync(recursive: true);
    });

    // Verifies: FR-PRJ-001
    test('starts with no project and no run', () {
      expect(controller.state.value, isA<WorkbenchEmpty>());
      expect(controller.runStatus.value, AppRunStatus.stopped);
      expect(controller.output.value, isEmpty);
    });

    // Verifies: FR-PRJ-001
    test('fails to open a directory that is not a Flutter project', () async {
      await controller.openProject(sandbox.path);

      expect(
        controller.state.value,
        isA<WorkbenchFailed>().having(
          (state) => state.failure,
          'failure',
          isA<NotAFlutterProject>(),
        ),
      );
    });

    // Verifies: FR-PRJ-003
    test('fails to open a project whose SDK is not found', () async {
      File(path.join(sandbox.path, 'pubspec.yaml')).writeAsStringSync('''
name: sample_app
dependencies:
  flutter:
    sdk: flutter
''');

      await controller.openProject(sandbox.path);

      expect(
        controller.state.value,
        isA<WorkbenchFailed>().having(
          (state) => state.failure,
          'failure',
          isA<SdkNotFound>(),
        ),
      );
    });
  });
}
