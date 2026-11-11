import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:studio_core/studio_core.dart';

import '../support/sdk_fixture.dart';

void main() {
  // Verifies: FR-PRJ-002
  group('SdkLocator', () {
    late Directory sandbox;
    late String projectPath;

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('sdk_locator_test');
      projectPath = createFlutterProject(sandbox);
    });

    tearDown(() {
      sandbox.deleteSync(recursive: true);
    });

    String createPinnedSdk(String version) {
      final cache = Directory(path.join(sandbox.path, 'fvm', 'versions'))
        ..createSync(recursive: true);
      final sdkPath = createSdk(cache, version: version);
      final pinnedPath = path.join(cache.path, version);
      Directory(sdkPath).renameSync(pinnedPath);
      File(path.join(projectPath, '.fvmrc'))
          .writeAsStringSync('{"flutter": "$version"}');
      return pinnedPath;
    }

    test('prefers the version pinned by the project', () {
      final pinnedPath = createPinnedSdk('3.44.1');
      final configuredPath = createSdk(sandbox, version: '3.47.9');
      final locator = SdkLocator(
        environment: {'HOME': sandbox.path, 'PATH': ''},
        configuredSdkPath: configuredPath,
      );

      expect(
        locator.locate(projectPath),
        FlutterSdk(rootPath: pinnedPath, version: const SdkVersion(3, 44, 1)),
      );
    });

    test('uses the configured SDK when the project pins none', () {
      final configuredPath = createSdk(sandbox, version: '3.47.9');
      final onPath = createSdk(
        Directory(path.join(sandbox.path, 'other'))..createSync(),
        version: '3.41.0',
      );
      final locator = SdkLocator(
        environment: {'PATH': path.join(onPath, 'bin')},
        configuredSdkPath: configuredPath,
      );

      expect(
        locator.locate(projectPath),
        FlutterSdk(
          rootPath: configuredPath,
          version: const SdkVersion(3, 47, 9),
        ),
      );
    });

    test('falls back to the SDK found on PATH', () {
      final onPath = createSdk(sandbox, version: '3.41.0');
      final locator = SdkLocator(
        environment: {'PATH': '/nonexistent:${path.join(onPath, 'bin')}'},
      );

      expect(locator.locate(projectPath).version, const SdkVersion(3, 41, 0));
    });

    test('fails when the pinned version is not installed', () {
      File(path.join(projectPath, '.fvmrc'))
          .writeAsStringSync('{"flutter": "3.38.0"}');
      final onPath = createSdk(sandbox, version: '3.47.9');
      final locator = SdkLocator(
        environment: {'HOME': sandbox.path, 'PATH': path.join(onPath, 'bin')},
      );

      expect(
        () => locator.locate(projectPath),
        throwsA(
          isA<SdkNotFound>().having(
            (failure) => failure.searchedPath,
            'searchedPath',
            path.join(sandbox.path, 'fvm', 'versions', '3.38.0'),
          ),
        ),
      );
    });

    test('fails when no source names an SDK', () {
      const locator = SdkLocator(environment: {'PATH': ''});

      expect(
        () => locator.locate(projectPath),
        throwsA(
          isA<SdkNotFound>().having(
            (failure) => failure.searchedPath,
            'searchedPath',
            isNull,
          ),
        ),
      );
    });
  });
}
