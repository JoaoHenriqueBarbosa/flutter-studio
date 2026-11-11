import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../document/document_change.dart';
import '../document/document_store.dart';
import '../document/edit_failure.dart';
import '../document/source_location.dart';
import 'widget_location.dart';

/// The single selection that every view and every client shares.
///
/// A Mediator: the views do not know each other, they set and observe the
/// selection here (FR-INS-003).
final class SelectionController {
  /// Creates the controller for the documents of [_documents].
  SelectionController(this._documents) {
    _changes = _documents.changes.listen(_handleChange);
  }

  final DocumentStore _documents;

  final _selection = ValueNotifier<WidgetLocation?>(null);

  late final StreamSubscription<DocumentChange> _changes;

  /// The selected widget, or `null` when nothing is selected.
  ///
  /// When the document of the selection changes, the selection moves to the
  /// new version of the document, at the same position.
  ValueListenable<WidgetLocation?> get selection => _selection;

  /// Selects the widget created at [location], in the current version of
  /// its document, and returns the selection.
  ///
  /// Throws [EditOutsideProject] when the file is not in the project, and a
  /// `FileSystemException` when it cannot be read.
  WidgetLocation select(SourceLocation location) {
    final filePath = path.normalize(location.filePath);
    if (!_documents.contains(filePath)) throw EditOutsideProject(filePath);
    final selected = (
      filePath: filePath,
      position: location.position,
      documentVersion: _documents.document(filePath).version,
    );
    _selection.value = selected;
    return selected;
  }

  /// Leaves nothing selected.
  void clear() => _selection.value = null;

  /// Releases the resources of the controller.
  Future<void> dispose() async {
    await _changes.cancel();
    _selection.dispose();
  }

  void _handleChange(DocumentChange change) {
    final selected = _selection.value;
    if (selected == null || selected.filePath != change.filePath) return;
    _selection.value = (
      filePath: selected.filePath,
      position: selected.position,
      documentVersion: change.document.version,
    );
  }
}
