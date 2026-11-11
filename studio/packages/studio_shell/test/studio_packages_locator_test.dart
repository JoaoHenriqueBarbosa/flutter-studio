import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:studio_shell/studio_shell.dart';

void main() {
  group('StudioPackagesLocator', () {
    late Directory sandbox;
    late String packagesPath;
    late String executablePath;

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('packages_locator');
      packagesPath = path.join(sandbox.path, 'studio', 'packages');
      File(path.join(packagesPath, 'studio_design_agent', 'pubspec.yaml'))
          .createSync(recursive: true);
      executablePath = path.join(
        packagesPath,
        'studio_shell',
        'build',
        'bundle',
        'studio_shell',
      );
    });

    tearDown(() => sandbox.deleteSync(recursive: true));

    // Verifies: FR-HST-001
    test('finds the packages above the executable of a local build', () {
      expect(
        const StudioPackagesLocator({}).locate(executablePath),
        packagesPath,
      );
    });

    // Verifies: FR-HST-001
    test('prefers the directory named in the environment', () {
      final elsewhere = path.join(sandbox.path, 'elsewhere');
      File(path.join(elsewhere, 'studio_design_agent', 'pubspec.yaml'))
          .createSync(recursive: true);
      final locator = StudioPackagesLocator({
        StudioPackagesLocator.environmentVariable: elsewhere,
      });

      expect(locator.locate(executablePath), elsewhere);
    });

    // Verifies: FR-HST-001
    test('finds nothing where the agent is not installed', () {
      const missing = StudioPackagesLocator({
        StudioPackagesLocator.environmentVariable: '/nowhere',
      });

      expect(missing.locate(executablePath), isNull);
      expect(const StudioPackagesLocator({}).locate('/usr/bin/studio'), isNull);
    });
  });
}
