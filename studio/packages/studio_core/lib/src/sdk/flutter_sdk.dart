import 'dart:io';

import 'package:path/path.dart' as path;

import 'sdk_version.dart';

/// A Flutter SDK installed on this machine.
final class FlutterSdk {
  /// Creates the description of the SDK at [rootPath], which is [version].
  const FlutterSdk({required this.rootPath, required this.version});

  /// Directory that contains the `bin` directory of the SDK.
  final String rootPath;

  /// Version that the SDK reports about itself.
  final SdkVersion version;

  /// Path of the `dart` executable of the SDK.
  String get dartPath => _executablePath('dart');

  /// Path of the `flutter` executable of the SDK.
  String get flutterPath => _executablePath('flutter');

  String _executablePath(String name) =>
      path.join(rootPath, 'bin', Platform.isWindows ? '$name.bat' : name);

  @override
  bool operator ==(Object other) =>
      other is FlutterSdk &&
      other.rootPath == rootPath &&
      other.version == version;

  @override
  int get hashCode => Object.hash(rootPath, version);

  @override
  String toString() => 'Flutter $version at $rootPath';
}
