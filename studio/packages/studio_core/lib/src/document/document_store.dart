import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import 'applied_edit.dart';
import 'change_origin.dart';
import 'document_change.dart';
import 'edit_failure.dart';
import 'text_document.dart';
import 'workspace_edit.dart';

/// The text of each file of one edit, before and after it.
typedef _Step = Map<String, ({String before, String after})>;

/// The only component that changes files of the project (ADR-0004).
///
/// Keeps the text and the version of each file it has touched. Every change
/// arrives as a [WorkspaceEdit] and reaches the disk through an atomic
/// write, so a failure never leaves a file partly written (NFR-REL-003).
///
/// Each applied edit is a Command kept on the undo stack with the full text
/// it replaced, so undoing restores the exact previous content (FR-DOC-006).
final class DocumentStore {
  /// Creates a store for the project rooted at [_rootPath].
  DocumentStore(this._rootPath);

  /// Suffix of the temporary file that an atomic write renames into place.
  static const _temporarySuffix = '.studio-tmp';

  final String _rootPath;

  final _documents = <String, TextDocument>{};

  final _changes = StreamController<DocumentChange>.broadcast();

  final _undoSteps = <_Step>[];

  final _redoSteps = <_Step>[];

  final _canUndo = ValueNotifier(false);

  final _canRedo = ValueNotifier(false);

  /// Each document, after a change to it has reached the disk.
  Stream<DocumentChange> get changes => _changes.stream;

  /// Whether there is an edit to undo.
  ValueListenable<bool> get canUndo => _canUndo;

  /// Whether there is an undone edit to redo.
  ValueListenable<bool> get canRedo => _canRedo;

  /// Whether the file at [filePath] is under the root of the project.
  bool contains(String filePath) =>
      path.isWithin(_rootPath, path.normalize(filePath));

  /// Returns the current document of the file at [filePath], reading it from
  /// disk the first time.
  ///
  /// Throws a [FileSystemException] when the file cannot be read.
  TextDocument document(String filePath) => _documents.putIfAbsent(
    path.normalize(filePath),
    () => TextDocument(
      File(filePath).readAsStringSync(),
      version: TextDocument.initialVersion,
    ),
  );

  /// Applies [edit], writes every changed file to disk and makes the edit
  /// the next one to undo.
  ///
  /// The new text of all files is computed before anything is written, so
  /// an invalid edit changes no file. Completes when all files are on disk.
  /// Throws [EditOutsideProject] when [edit] names a file outside the
  /// project, and [InvalidEdit] for invalid ranges.
  Future<AppliedEdit> apply(WorkspaceEdit edit) async {
    final updated = <String, TextDocument>{};
    final changes = <FileEdit>[];
    for (final fileEdit in edit.fileEdits) {
      final filePath = path.normalize(fileEdit.filePath);
      if (!contains(filePath)) throw EditOutsideProject(filePath);
      final current = updated[filePath] ?? document(filePath);
      updated[filePath] = current.applying(fileEdit.edits);
      changes.add((filePath: filePath, edits: fileEdit.edits));
    }
    final step = {
      for (final MapEntry(key: filePath, value: next) in updated.entries)
        filePath: (before: document(filePath).text, after: next.text),
    };
    await _commit(updated);
    _undoSteps.add(step);
    _redoSteps.clear();
    _announceHistory();
    return AppliedEdit(changes: changes, versions: _versionsOf(updated));
  }

  /// Undoes the last edit and writes the previous text of its files.
  ///
  /// Completes with what was changed, or with `null` when there is nothing
  /// to undo.
  Future<AppliedEdit?> undo() => _revert(_undoSteps, _redoSteps);

  /// Applies again the edit that the last [undo] removed.
  ///
  /// Completes with what was changed, or with `null` when there is nothing
  /// to redo.
  Future<AppliedEdit?> redo() => _revert(_redoSteps, _undoSteps);

  /// Releases the resources of the store. No edit may be applied afterwards.
  Future<void> dispose() async {
    await _changes.close();
    _canUndo.dispose();
    _canRedo.dispose();
  }

  /// Takes the last step of [source], restores the text its files had
  /// before it, and leaves the opposite step on [destination].
  Future<AppliedEdit?> _revert(
    List<_Step> source,
    List<_Step> destination,
  ) async {
    final step = source.lastOrNull;
    if (step == null) return null;
    final updated = <String, TextDocument>{};
    final changes = <FileEdit>[];
    for (final MapEntry(key: filePath, value: texts) in step.entries) {
      final current = document(filePath);
      changes.add((filePath: filePath, edits: [current.editTo(texts.before)]));
      updated[filePath] = current.replacing(texts.before);
    }
    await _commit(updated);
    source.removeLast();
    destination.add({
      for (final MapEntry(key: filePath, value: texts) in step.entries)
        filePath: (before: texts.after, after: texts.before),
    });
    _announceHistory();
    return AppliedEdit(changes: changes, versions: _versionsOf(updated));
  }

  Future<void> _commit(Map<String, TextDocument> updated) async {
    for (final MapEntry(key: filePath, value: document) in updated.entries) {
      await _writeAtomically(filePath, document.text);
      _documents[filePath] = document;
      _changes.add((
        filePath: filePath,
        document: document,
        origin: ChangeOrigin.studio,
      ));
    }
  }

  Map<String, int> _versionsOf(Map<String, TextDocument> documents) => {
    for (final MapEntry(key: filePath, value: document) in documents.entries)
      filePath: document.version,
  };

  void _announceHistory() {
    _canUndo.value = _undoSteps.isNotEmpty;
    _canRedo.value = _redoSteps.isNotEmpty;
  }

  /// Writes [text] to a temporary file beside [filePath] and renames it
  /// into place. The rename replaces the file in one step on every
  /// supported system, and holds no lock on it (NFR-COMP-001).
  Future<void> _writeAtomically(String filePath, String text) async {
    final temporary = File('$filePath$_temporarySuffix');
    await temporary.writeAsString(text, flush: true);
    await temporary.rename(filePath);
  }
}
