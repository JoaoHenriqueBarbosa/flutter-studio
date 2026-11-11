import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '../project/flutter_project.dart';

/// The host project of a design session: a Flutter project generated under
/// `.dart_tool/studio/host/` of the project of the user, which starts the
/// design agent and then the app of the project (FR-HST-001, ADR-0008).
///
/// The project of the user receives no dependency and no file outside
/// `.dart_tool/` (DC-02).
final class DesignHostProject {
  /// Creates the host of [_project].
  ///
  /// [_studioPackagesPath] is the directory that holds the sources of
  /// `studio_design_agent` and of `studio_protocol`, which the host
  /// compiles with the SDK of the project.
  const DesignHostProject(this._project, this._studioPackagesPath);

  static const _manifestFileName = 'pubspec.yaml';

  /// Constraint used when the project declares none. It admits every SDK
  /// of the supported window.
  static const _anySupportedSdk = '>=3.10.0 <4.0.0';

  final FlutterProject _project;

  final String _studioPackagesPath;

  /// Directory of the host project.
  String get rootPath =>
      path.join(_project.rootPath, '.dart_tool', 'studio', 'host');

  /// Writes the files of the host and resolves its packages, offline.
  ///
  /// Nothing is written when the files are already the ones this version
  /// generates and the packages are resolved. Throws a [ProcessException]
  /// when the packages cannot be resolved.
  Future<void> generate() async {
    final isManifestNew = _write(_manifestFileName, _manifest());
    _write(path.join('lib', 'main.dart'), _entryPoint());
    final packageConfig = File(
      path.join(rootPath, '.dart_tool', 'package_config.json'),
    );
    if (!isManifestNew && packageConfig.existsSync()) return;
    const arguments = ['pub', 'get', '--offline'];
    final result = await Process.run(
      _project.sdk.flutterPath,
      arguments,
      workingDirectory: rootPath,
    );
    if (result.exitCode != 0) {
      throw ProcessException(
        _project.sdk.flutterPath,
        arguments,
        '${result.stderr}',
        result.exitCode,
      );
    }
  }

  /// Writes [content] to the file [relativePath] of the host, unless the
  /// file has that content already, and returns whether it wrote.
  bool _write(String relativePath, String content) {
    final file = File(path.join(rootPath, relativePath));
    if (file.existsSync() && file.readAsStringSync() == content) return false;
    file
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
    return true;
  }

  String _manifest() =>
      '''
# GENERATED CODE - DO NOT MODIFY BY HAND
name: studio_design_host
publish_to: none

environment:
  sdk: "${_sdkConstraint()}"

dependencies:
  flutter:
    sdk: flutter
  ${_project.name}:
    path: ${_project.rootPath}
  studio_design_agent:
    path: ${path.join(_studioPackagesPath, 'studio_design_agent')}

dependency_overrides:
  studio_protocol:
    path: ${path.join(_studioPackagesPath, 'studio_protocol')}

flutter:
  uses-material-design: true
''';

  String _entryPoint() =>
      '''
// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: the project at ${_project.rootPath}. Generator: Studio.

import 'package:${_project.name}/main.dart' as project;
import 'package:studio_design_agent/studio_design_agent.dart';

void main() {
  const DesignAgent(['${Uri.directory(_project.rootPath)}']).start();
  project.main();
}
''';

  /// Returns the SDK constraint of the project, so that the host is
  /// compiled with the same language version.
  String _sdkConstraint() {
    final manifest = File(path.join(_project.rootPath, _manifestFileName));
    final Object? document = loadYaml(manifest.readAsStringSync());
    return switch (document) {
      {'environment': {'sdk': final String constraint}} => constraint,
      _ => _anySupportedSdk,
    };
  }
}
