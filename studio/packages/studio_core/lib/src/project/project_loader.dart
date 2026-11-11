import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '../sdk/sdk_locator.dart';
import '../sdk/sdk_version_window.dart';
import 'flutter_project.dart';
import 'project_open_failure.dart';

/// Opens a directory as a Flutter project (FR-PRJ-001).
///
/// Opening only reads: no file of the project is created or changed.
final class ProjectLoader {
  /// Creates a loader that finds SDKs with [_locator] and accepts the ones
  /// inside [window].
  const ProjectLoader(
    this._locator, {
    this.window = SdkVersionWindow.supported,
  });

  static const _manifestFileName = 'pubspec.yaml';

  final SdkLocator _locator;

  /// Versions of the SDK that a project may use (FR-PRJ-003).
  final SdkVersionWindow window;

  /// Returns the project at [projectPath] with its SDK.
  ///
  /// Throws a [ProjectOpenFailure] when the directory is not a Flutter
  /// project, when its SDK is not found, or when the SDK is outside
  /// [window].
  FlutterProject load(String projectPath) {
    final rootPath = path.normalize(path.absolute(projectPath));
    final name = _flutterPackageName(rootPath);
    if (name == null) throw NotAFlutterProject(rootPath);
    final sdk = _locator.locate(rootPath);
    if (!window.contains(sdk.version)) {
      throw SdkOutsideWindow(found: sdk.version, window: window);
    }
    return FlutterProject(rootPath: rootPath, name: name, sdk: sdk);
  }

  /// Returns the package name when the manifest depends on the Flutter SDK.
  String? _flutterPackageName(String rootPath) {
    final manifest = File(path.join(rootPath, _manifestFileName));
    if (!manifest.existsSync()) return null;
    final Object? document = loadYaml(manifest.readAsStringSync());
    if (document case {
      'name': final String name,
      'dependencies': {'flutter': {'sdk': 'flutter'}},
    }) {
      return name;
    }
    return null;
  }
}
