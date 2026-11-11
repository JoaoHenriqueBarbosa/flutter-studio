import 'dart:async';

import 'package:path/path.dart' as path;

import '../document/document_store.dart';
import '../document/edit_failure.dart';
import '../lsp/document_sync.dart';
import '../lsp/file_outline.dart';
import '../lsp/lsp_client.dart';
import 'source_tree.dart';
import 'source_tree_builder.dart';

/// The source trees of the files that are open in the analysis server,
/// kept up to date with the outlines that the server publishes.
final class SourceTrees {
  /// Creates the trees of the documents of [_documents], which are opened
  /// in the server through [_sync].
  ///
  /// [treeOf] gives up after [patience] without an outline of the version
  /// it waits for.
  SourceTrees(
    this._documents,
    this._sync, {
    this.patience = const Duration(seconds: 15),
  });

  /// Name of the analysis server in a [ToolUnavailable].
  static const _serverName = 'analysis-server';

  final DocumentStore _documents;

  final DocumentSync _sync;

  /// How long [treeOf] waits for the server to publish an outline.
  final Duration patience;

  final _trees = <String, SourceTree>{};

  final _changes = StreamController<SourceTree>.broadcast();

  StreamSubscription<FileOutline>? _outlines;

  /// Each tree, when the server publishes a new outline of its file.
  Stream<SourceTree> get changes => _changes.stream;

  /// Starts building the trees from the outlines of [server], in place of
  /// the server that was attached before.
  void attach(LspClient server) {
    unawaited(_outlines?.cancel());
    _outlines = server.outlines.listen(_handleOutline);
  }

  /// Completes with the tree of the file at [filePath], at the current
  /// version of its document.
  ///
  /// The file is opened in the server, which publishes outlines only of
  /// open files. Throws [ToolUnavailable] when no server is attached or
  /// the server publishes no outline of the current version in time.
  Future<SourceTree> treeOf(String filePath) async {
    final normalized = path.normalize(filePath);
    if (_outlines == null) throw const ToolUnavailable(_serverName);
    _sync.ensureOpen(normalized);
    bool isCurrent(SourceTree tree) =>
        tree.filePath == normalized &&
        tree.documentVersion == _documents.document(normalized).version;
    final known = _trees[normalized];
    if (known != null && isCurrent(known)) return known;
    try {
      return await changes.firstWhere(isCurrent).timeout(patience);
    } on TimeoutException {
      throw const ToolUnavailable(_serverName);
    }
  }

  /// Stops following the server and releases the resources.
  Future<void> dispose() async {
    await _outlines?.cancel();
    await _changes.close();
  }

  /// Builds the tree of an outline. The outline carries no version: it is
  /// taken as the outline of the version that the store has when it
  /// arrives, which is the last one sent to the server.
  void _handleOutline(FileOutline outline) {
    final filePath = path.normalize(outline.filePath);
    if (!_documents.isLoaded(filePath)) return;
    final document = _documents.document(filePath);
    final tree = (
      filePath: filePath,
      documentVersion: document.version,
      roots: SourceTreeBuilder(document).build(outline.root),
    );
    _trees[filePath] = tree;
    _changes.add(tree);
  }
}
