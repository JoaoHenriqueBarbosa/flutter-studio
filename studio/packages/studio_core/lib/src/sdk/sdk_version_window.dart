import 'sdk_version.dart';

/// The stable release lines of Flutter that Studio works with
/// (NFR-FLEX-001).
final class SdkVersionWindow {
  /// Creates a window made of [releaseLines], each a major and a minor
  /// number, oldest first.
  const SdkVersionWindow(this.releaseLines);

  /// The four most recent stable release lines.
  static const supported = SdkVersionWindow([
    (major: 3, minor: 38),
    (major: 3, minor: 41),
    (major: 3, minor: 44),
    (major: 3, minor: 47),
  ]);

  /// Release lines inside the window, oldest first.
  final List<({int major, int minor})> releaseLines;

  /// Whether [version] belongs to one of the release lines of the window.
  bool contains(SdkVersion version) =>
      releaseLines.contains((major: version.major, minor: version.minor));

  @override
  String toString() =>
      [for (final line in releaseLines) '${line.major}.${line.minor}']
          .join(', ');
}
