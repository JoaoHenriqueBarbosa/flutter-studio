import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:studio_core/studio_core.dart';

import '../support/sample_app.dart';

void main() {
  group('DesignHostProject', () {
    late Directory sandbox;
    late FlutterProject project;
    late DesignHostProject host;

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('design_host_test');
      project = ProjectLoader(SdkLocator(environment: Platform.environment))
          .load(createSampleApp(sandbox));
      host = DesignHostProject(project, Directory.current.parent.path);
    });

    tearDown(() => sandbox.deleteSync(recursive: true));

    String read(String relativePath) =>
        File(path.join(host.rootPath, relativePath)).readAsStringSync();

    // Verifies: FR-HST-001, FR-PRJ-001
    test(
      'generates under .dart_tool a project that starts the agent',
      () async {
        await host.generate();

        expect(
          path.isWithin(
            path.join(project.rootPath, '.dart_tool'),
            host.rootPath,
          ),
          isTrue,
        );
        expect(
          read('pubspec.yaml'),
          allOf(
            contains('  sample_app:\n    path: ${project.rootPath}\n'),
            contains('studio_design_agent:\n    path: '),
          ),
        );
        expect(
          read(path.join('lib', 'main.dart')),
          allOf(
            contains("import 'package:sample_app/main.dart' as project;"),
            contains("DesignAgent(['${Uri.directory(project.rootPath)}'])"),
            contains('project.main();'),
          ),
        );
        expect(
          File(path.join(host.rootPath, '.dart_tool', 'package_config.json'))
              .existsSync(),
          isTrue,
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    // Verifies: FR-HST-001
    test('writes nothing when the host is already generated', () async {
      await host.generate();
      final manifest = File(path.join(host.rootPath, 'pubspec.yaml'));
      final writtenAt = manifest.lastModifiedSync();

      await host.generate();

      expect(manifest.lastModifiedSync(), writtenAt);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
