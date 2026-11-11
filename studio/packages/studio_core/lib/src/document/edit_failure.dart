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

/// An edit was made for a version of the document that is not the current
/// one. Whoever asked has to read the document again.
final class StaleDocument extends EditFailure {
  /// Creates the failure for a document now at [currentVersion].
  const StaleDocument(this.currentVersion);

  /// Version of the document in the store.
  final int currentVersion;

  @override
  String toString() => 'The document is at version $currentVersion.';
}

/// The target does not accept the edit that was asked for.
final class UnsupportedEdit extends EditFailure {
  /// Creates the failure explained by [reason].
  const UnsupportedEdit(this.reason);

  /// Why the edit cannot be made.
  final String reason;

  @override
  String toString() => 'Unsupported edit: $reason';
}

/// A tool that the edit needs is not running.
final class ToolUnavailable extends EditFailure {
  /// Creates the failure for the tool called [toolName].
  const ToolUnavailable(this.toolName);

  /// Name of the process that is not running.
  final String toolName;

  @override
  String toString() => '$toolName is not running.';
}
