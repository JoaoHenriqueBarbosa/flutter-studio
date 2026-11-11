import 'dart:async';

import 'package:path/path.dart' as path;

import '../document/document_change.dart';
import '../document/document_store.dart';
import 'lsp_client.dart';

/// Keeps the analysis server reading the documents of the store, with the
/// versions of the store, instead of the files on disk.
///
/// A document enters with [ensureOpen] and follows every change of the
/// store from then on. When the server restarts, [attach] opens the same
/// documents in the new one (NFR-REL-002).
final class DocumentSync {
  /// Creates the synchronizer of [_documents]. It sends nothing until a
  /// server is given to [attach].
  DocumentSync(this._documents) {
    _changes = _documents.changes.listen(_handleChange);
  }

  final DocumentStore _documents;

  /// Version that the current server has of each open document, by path.
  /// A path with no entry is open in the store but not yet in the server.
  final _sentVersions = <String, int>{};

  final _openPaths = <String>{};

  late final StreamSubscription<DocumentChange> _changes;

  LspClient? _server;

  /// Makes [server] the one that receives the documents and opens in it
  /// every document opened so far.
  void attach(LspClient server) {
    _server = server;
    _sentVersions.clear();
    _openPaths.forEach(_send);
  }

  /// Opens the file at [filePath] in the server, unless it is open already.
  ///
  /// Throws a `FileSystemException` when the file cannot be read.
  void ensureOpen(String filePath) {
    final normalized = path.normalize(filePath);
    _documents.document(normalized);
    if (_openPaths.add(normalized)) _send(normalized);
  }

  /// Stops following the store.
  Future<void> dispose() => _changes.cancel();

  void _handleChange(DocumentChange change) {
    if (_openPaths.contains(change.filePath)) _send(change.filePath);
  }

  /// Sends the current document at [filePath] to the server, unless the
  /// server already has that version.
  void _send(String filePath) {
    final server = _server;
    final document = _documents.document(filePath);
    final sentVersion = _sentVersions[filePath];
    if (server == null || sentVersion == document.version) return;
    if (sentVersion == null) {
      server.openDocument(filePath, document);
    } else {
      server.changeDocument(filePath, document);
    }
    _sentVersions[filePath] = document.version;
  }
}
