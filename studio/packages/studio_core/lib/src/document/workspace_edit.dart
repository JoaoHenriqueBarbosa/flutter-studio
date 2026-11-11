import 'text_edit.dart';

/// The edits of one file inside a [WorkspaceEdit].
///
/// The ranges of `edits` refer to the text before any of them is applied,
/// and do not overlap.
typedef FileEdit = ({String filePath, List<TextEdit> edits});

/// A change to the files of the project, applied as one step (FR-DOC-001).
final class WorkspaceEdit {
  /// Creates an edit made of [fileEdits], one entry for each file.
  const WorkspaceEdit(this.fileEdits);

  /// Edits grouped by file.
  final List<FileEdit> fileEdits;

  @override
  String toString() => 'WorkspaceEdit($fileEdits)';
}
