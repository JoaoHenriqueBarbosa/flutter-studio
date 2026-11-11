import '../sdk/sdk_version.dart';
import '../sdk/sdk_version_window.dart';

/// Reason why a directory could not be opened as a project.
sealed class ProjectOpenFailure implements Exception {
  const ProjectOpenFailure();
}

/// The directory has no `pubspec.yaml` that depends on the Flutter SDK.
final class NotAFlutterProject extends ProjectOpenFailure {
  /// Creates the failure for the directory at [projectPath].
  const NotAFlutterProject(this.projectPath);

  /// Directory that was asked to open.
  final String projectPath;

  @override
  String toString() => '$projectPath is not a Flutter project.';
}

/// No Flutter SDK was found for the project (FR-PRJ-002).
final class SdkNotFound extends ProjectOpenFailure {
  /// Creates the failure. [searchedPath] is the place that the project or
  /// the configuration pointed to, or `null` when `PATH` has no SDK.
  const SdkNotFound({this.searchedPath});

  /// Directory that should hold the SDK and does not, or `null` when no
  /// source named a directory.
  final String? searchedPath;

  @override
  String toString() => searchedPath == null
      ? 'No Flutter SDK was found.'
      : 'No Flutter SDK was found at $searchedPath.';
}

/// The SDK of the project is outside the supported window (FR-PRJ-003).
final class SdkOutsideWindow extends ProjectOpenFailure {
  /// Creates the failure for an SDK of version [found].
  const SdkOutsideWindow({required this.found, required this.window});

  /// Version of the SDK that was located.
  final SdkVersion found;

  /// Window of versions that Studio works with.
  final SdkVersionWindow window;

  @override
  String toString() =>
      'Flutter $found is outside the supported versions: $window.';
}
