import '../sdk/flutter_sdk.dart';

/// A Flutter project opened by Studio.
final class FlutterProject {
  /// Creates the description of the project at [rootPath].
  const FlutterProject({
    required this.rootPath,
    required this.name,
    required this.sdk,
  });

  /// Directory that contains the `pubspec.yaml` of the project.
  final String rootPath;

  /// Package name declared in the `pubspec.yaml`.
  final String name;

  /// SDK that analyzes and runs the project (ADR-0011).
  final FlutterSdk sdk;

  @override
  bool operator ==(Object other) =>
      other is FlutterProject &&
      other.rootPath == rootPath &&
      other.name == name &&
      other.sdk == sdk;

  @override
  int get hashCode => Object.hash(rootPath, name, sdk);

  @override
  String toString() => 'FlutterProject($name at $rootPath, $sdk)';
}
