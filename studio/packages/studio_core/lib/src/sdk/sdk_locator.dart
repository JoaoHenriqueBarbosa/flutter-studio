import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../project/project_open_failure.dart';
import 'flutter_sdk.dart';
import 'sdk_version.dart';

/// Finds the Flutter SDK of a project (FR-PRJ-002).
///
/// The sources are tried in this order: the version pinned by the project
/// in `.fvmrc`, the SDK configured in Studio, and the `PATH` variable. The
/// first source that names a directory decides: a missing SDK there is a
/// failure, not a reason to try the next source.
final class SdkLocator {
  /// Creates a locator that reads `PATH` and the home directory from
  /// [environment]. [configuredSdkPath] is the SDK chosen in the Studio
  /// preferences, or `null` when none was chosen.
  const SdkLocator({required this.environment, this.configuredSdkPath});

  /// File in which FVM pins the Flutter version of a project.
  static const _pinFileName = '.fvmrc';

  /// File in which an SDK records its own version.
  static const _versionFilePath = 'bin/cache/flutter.version.json';

  /// Environment variables of the process.
  final Map<String, String> environment;

  /// Root directory of the SDK chosen in the Studio preferences.
  final String? configuredSdkPath;

  /// Returns the SDK of the project at [projectPath].
  ///
  /// Throws [SdkNotFound] when no source names an SDK, or when the directory
  /// named by the first source that names one holds no SDK.
  FlutterSdk locate(String projectPath) {
    final rootPath =
        _pinnedSdkPath(projectPath) ?? configuredSdkPath ?? _sdkPathOnPath();
    if (rootPath == null) throw const SdkNotFound();
    final version = _readVersion(rootPath);
    if (version == null) throw SdkNotFound(searchedPath: rootPath);
    return FlutterSdk(rootPath: rootPath, version: version);
  }

  String? _pinnedSdkPath(String projectPath) {
    final pinFile = File(path.join(projectPath, _pinFileName));
    if (!pinFile.existsSync()) return null;
    final Object? pin = jsonDecode(pinFile.readAsStringSync());
    if (pin case {'flutter': final String version}) {
      return path.join(_fvmCachePath, 'versions', version);
    }
    return null;
  }

  String get _fvmCachePath =>
      environment['FVM_CACHE_PATH'] ??
      path.join(environment['HOME'] ?? environment['USERPROFILE'] ?? '', 'fvm');

  String? _sdkPathOnPath() {
    final executableName = Platform.isWindows ? 'flutter.bat' : 'flutter';
    final separator = Platform.isWindows ? ';' : ':';
    for (final directory in (environment['PATH'] ?? '').split(separator)) {
      final executable = File(path.join(directory, executableName));
      if (executable.existsSync()) {
        final resolvedPath = executable.resolveSymbolicLinksSync();
        return path.dirname(path.dirname(resolvedPath));
      }
    }
    return null;
  }

  SdkVersion? _readVersion(String rootPath) {
    final versionFile = File(path.join(rootPath, _versionFilePath));
    if (!versionFile.existsSync()) return null;
    final Object? record = jsonDecode(versionFile.readAsStringSync());
    if (record case {'flutterVersion': final String version}) {
      return SdkVersion.tryParse(version);
    }
    return null;
  }
}
