import 'workspace_edit.dart';

/// What the document store did when it applied, undid or redid an edit.
final class AppliedEdit {
  /// Creates the report of an edit that made [changes] and left each file
  /// at the version in [versions].
  const AppliedEdit({required this.changes, required this.versions});

  /// The text edits that were made, grouped by file. The ranges refer to
  /// the text before the edit.
  final List<FileEdit> changes;

  /// Version of each changed file after the edit, by file path.
  final Map<String, int> versions;

  @override
  String toString() => 'AppliedEdit($changes, $versions)';
}
