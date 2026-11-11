import '../document/applied_edit.dart';

/// How an operation of the edit pipeline ended.
final class EditOutcome {
  /// Creates the outcome of an operation that made [edit], or changed
  /// nothing when [edit] is `null`.
  const EditOutcome({required this.edit, required this.isReloadRequested});

  /// What changed in the documents, or `null` when nothing changed.
  final AppliedEdit? edit;

  /// Whether the running app was asked to hot reload.
  final bool isReloadRequested;
}
