import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:studio_core/studio_core.dart';

import '../support/sdk_fixture.dart';

void main() {
  group('ProjectLoader', () {
    late Directory sandbox;

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('project_loader_test');
    });

    tearDown(() {
      sandbox.deleteSync(recursive: true);
    });

    ProjectLoader loaderWithSdk(String version) => ProjectLoader(
      SdkLocator(
        environment: const {'PATH': ''},
        configuredSdkPath: createSdk(sandbox, version: version),
      ),
    );

    // Verifies: FR-PRJ-001
    test('loads a directory whose pubspec depends on Flutter', () {
      final projectPath = createFlutterProject(sandbox);

      final project = loaderWithSdk('3.47.9').load(projectPath);

      expect(project.name, 'sample_app');
      expect(project.rootPath, projectPath);
      expect(project.sdk.version, const SdkVersion(3, 47, 9));
    });

    // Verifies: FR-PRJ-001
    test('does not create or change any file of the project', () {
      final projectPath = createFlutterProject(sandbox);
      List<String> listing() => [
        for (final entity in Directory(projectPath).listSync(recursive: true))
          '${entity.path} ${entity.statSync().modified}',
      ];
      final before = listing();

      loaderWithSdk('3.47.9').load(projectPath);

      expect(listing(), before);
    });

    // Verifies: FR-PRJ-001
    test('rejects a Dart package that does not depend on Flutter', () {
      final projectPath = path.join(sandbox.path, 'dart_only');
      File(path.join(projectPath, 'pubspec.yaml'))
        ..createSync(recursive: true)
        ..writeAsStringSync('name: dart_only\n');

      expect(
        () => loaderWithSdk('3.47.9').load(projectPath),
        throwsA(
          isA<NotAFlutterProject>().having(
            (failure) => failure.projectPath,
            'projectPath',
            projectPath,
          ),
        ),
      );
    });

    // Verifies: FR-PRJ-001
    test('rejects a directory without pubspec', () {
      expect(
        () => loaderWithSdk('3.47.9').load(sandbox.path),
        throwsA(isA<NotAFlutterProject>()),
      );
    });

    // Verifies: FR-PRJ-003
    test('reports the version found and the window when outside it', () {
      final projectPath = createFlutterProject(sandbox);

      expect(
        () => loaderWithSdk('3.35.2').load(projectPath),
        throwsA(
          isA<SdkOutsideWindow>()
              .having(
                (failure) => failure.found,
                'found',
                const SdkVersion(3, 35, 2),
              )
              .having(
                (failure) => '$failure',
                'message',
                'Flutter 3.35.2 is outside the supported versions: '
                    '3.38, 3.41, 3.44, 3.47.',
              ),
        ),
      );
    });
  });
}
