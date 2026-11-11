/// An edit names a file that is not under the root of the project (IR-005).
final class EditOutsideProject implements Exception {
  /// Creates the failure for the file at [filePath].
  const EditOutsideProject(this.filePath);

  /// File that the edit tried to change.
  final String filePath;

  @override
  String toString() => '$filePath is outside the project.';
}
