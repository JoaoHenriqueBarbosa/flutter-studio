import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'edit_outside_project.dart';
import 'text_document.dart';
import 'workspace_edit.dart';

/// The only component that changes files of the project (ADR-0004).
///
/// Keeps the text and the version of each file it has touched. Every change
/// arrives as a [WorkspaceEdit] and reaches the disk through an atomic
/// write, so a failure never leaves a file partly written (NFR-REL-003).
final class DocumentStore {
  /// Creates a store for the project rooted at [_rootPath].
  DocumentStore(this._rootPath);

  /// Suffix of the temporary file that an atomic write renames into place.
  static const _temporarySuffix = '.studio-tmp';

  final String _rootPath;

  final _documents = <String, TextDocument>{};

  final _changedFiles = StreamController<String>.broadcast();

  /// Path of each file, after an edit to it has reached the disk.
  Stream<String> get changedFiles => _changedFiles.stream;

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

  /// Applies [edit] and writes every changed file to disk.
  ///
  /// The new text of all files is computed before anything is written, so
  /// an invalid edit changes no file. Completes when all files are on disk.
  /// Throws [EditOutsideProject] when [edit] names a file outside the
  /// project, and the errors of [TextDocument.applying] for invalid ranges.
  Future<void> apply(WorkspaceEdit edit) async {
    final updated = <String, TextDocument>{};
    for (final fileEdit in edit.fileEdits) {
      final filePath = path.normalize(fileEdit.filePath);
      if (!path.isWithin(_rootPath, filePath)) {
        throw EditOutsideProject(filePath);
      }
      final current = updated[filePath] ?? document(filePath);
      updated[filePath] = current.applying(fileEdit.edits);
    }
    for (final MapEntry(key: filePath, value: document) in updated.entries) {
      await _writeAtomically(filePath, document.text);
      _documents[filePath] = document;
      _changedFiles.add(filePath);
    }
  }

  /// Releases the resources of the store. No edit may be applied afterwards.
  Future<void> dispose() => _changedFiles.close();

  /// Writes [text] to a temporary file beside [filePath] and renames it
  /// into place. The rename replaces the file in one step on every
  /// supported system, and holds no lock on it (NFR-COMP-001).
  Future<void> _writeAtomically(String filePath, String text) async {
    final temporary = File('$filePath$_temporarySuffix');
    await temporary.writeAsString(text, flush: true);
    await temporary.rename(filePath);
  }
}
