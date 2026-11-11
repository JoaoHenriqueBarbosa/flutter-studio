/// Reason why the document store refused an edit. No file is changed when
/// an edit is refused.
sealed class EditFailure implements Exception {
  const EditFailure();
}

/// An edit cannot be applied to the text it was made for.
final class InvalidEdit extends EditFailure {
  /// Creates the failure described by [message].
  const InvalidEdit(this.message);

  /// What is wrong with the edit.
  final String message;

  @override
  String toString() => 'Invalid edit: $message';
}

/// An edit names a file that is not under the root of the project (IR-005).
final class EditOutsideProject extends EditFailure {
  /// Creates the failure for the file at [filePath].
  const EditOutsideProject(this.filePath);

  /// File that the edit tried to change.
  final String filePath;

  @override
  String toString() => '$filePath is outside the project.';
}
