import 'dart:async';

import 'package:devtools_app_shared/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:studio_core/studio_core.dart'
    show DocumentChange, WidgetLocation;
import 'package:studio_protocol/studio_protocol.dart';

/// Shows the source tree of one file and keeps it in step with the code
/// and with the selection (FR-INS-002, FR-INS-003).
///
/// The file is the one of the selection, once there is a selection, and
/// the tree is read again from the `Studio` service after each change of
/// its document.
final class SourceTreeController extends DisposableController
    with AutoDisposeControllerMixin {
  /// Creates a controller that reads from [_studio] and follows
  /// [selection] and [documentChanges].
  ///
  /// The tree of the file at [initialFilePath] is shown until something is
  /// selected in another file.
  SourceTreeController(
    this._studio,
    this.selection,
    Stream<DocumentChange> documentChanges, {
    required String initialFilePath,
  }) : _filePath = initialFilePath {
    addAutoDisposeListener(selection, _handleSelection);
    autoDisposeStreamSubscription(documentChanges.listen(_handleChange));
    unawaited(_read());
  }

  final StudioApi _studio;

  /// The selection shared with the other views.
  final ValueListenable<WidgetLocation?> selection;

  final _roots = ValueNotifier<List<SourceNode>>(const []);

  String _filePath;

  /// Number of the last read that started. A read that ends after a newer
  /// one started is dropped.
  var _readCount = 0;

  /// The widgets of the file that no other widget contains. Empty while
  /// the tree is not known.
  ValueListenable<List<SourceNode>> get roots => _roots;

  /// Whether [node] is the selected widget.
  bool isSelected(SourceNode node) {
    final selected = selection.value;
    return selected != null &&
        node.ref.uri == '${Uri.file(selected.filePath)}' &&
        node.ref.position.line == selected.position.line &&
        node.ref.position.character == selected.position.character;
  }

  /// Selects [node] in every view, through the service.
  Future<void> select(SourceNode node) async {
    try {
      await _studio.select(target: node.ref);
    } on StudioFault {
      // The tree on screen is of an older version of the document. The
      // read that the change started brings the current one.
    }
  }

  @override
  void dispose() {
    // Drops a read that is still on its way.
    _readCount++;
    _roots.dispose();
    super.dispose();
  }

  void _handleSelection() {
    final selected = selection.value;
    if (selected == null || selected.filePath == _filePath) return;
    _filePath = selected.filePath;
    unawaited(_read());
  }

  void _handleChange(DocumentChange change) {
    if (change.filePath == _filePath) unawaited(_read());
  }

  Future<void> _read() async {
    final read = ++_readCount;
    var roots = const <SourceNode>[];
    try {
      roots = await _studio.getSourceTree(uri: '${Uri.file(_filePath)}');
    } on StudioFault {
      // The file is gone or the server is restarting. The tree stays empty
      // until the next change.
    }
    if (read == _readCount) _roots.value = roots;
  }
}
