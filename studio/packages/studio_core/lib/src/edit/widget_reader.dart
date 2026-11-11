import 'package:studio_protocol/studio_protocol.dart' show Scene;

import '../document/edit_failure.dart';
import '../document/source_location.dart';
import '../lsp/document_sync.dart';
import '../lsp/editable_argument.dart';
import '../lsp/lsp_client.dart';
import '../lsp/lsp_request_failed.dart';
import '../lsp/server_assist.dart';
import '../structure/source_tree.dart';
import '../structure/source_trees.dart';

/// Reads from the analysis server what it knows about the widget created
/// at a location.
final class WidgetReader {
  /// Creates a reader that opens documents through [_sync] and takes the
  /// source trees from [_trees].
  ///
  /// [_server] returns the current client of the analysis server, or `null`
  /// while the server is not running. [runningScene] returns the scene of
  /// the frame on the canvas, or `null` while no app with the design agent
  /// is running.
  const WidgetReader(
    this._sync,
    this._trees,
    this._server, {
    required this.runningScene,
  });

  /// Name of the analysis server in a [ToolUnavailable].
  static const serverName = 'analysis-server';

  final DocumentSync _sync;

  final SourceTrees _trees;

  final LspClient? Function() _server;

  /// Returns the scene mirror of the running app, when there is one.
  final Scene? Function() runningScene;

  /// Completes with the parameters of the constructor called at [target].
  ///
  /// Throws [ToolUnavailable] while the server is down and
  /// [UnsupportedEdit] when [target] does not create a widget.
  Future<List<EditableArgument>> arguments(SourceLocation target) async {
    final arguments = await _ask(
      target,
      (server) => server.editableArguments(target),
    );
    if (arguments != null) return arguments;
    throw const UnsupportedEdit('No widget is created at the position.');
  }

  /// Completes with the Flutter assists that the server offers at
  /// [target].
  ///
  /// Throws [ToolUnavailable] while the server is down.
  Future<List<ServerAssist>> assists(SourceLocation target) =>
      _ask(target, (server) => server.assists(target));

  /// Makes sure that the server has the current version of the document
  /// of [target], before a request about it that this class does not make.
  void openDocumentOf(SourceLocation target) =>
      _sync.ensureOpen(target.filePath);

  /// Completes with the widgets that the source of the file at [filePath]
  /// creates.
  ///
  /// Throws [ToolUnavailable] while the server is down.
  Future<SourceTree> sourceTree(String filePath) => _trees.treeOf(filePath);

  /// Opens the document of [target] in the server, so that the server reads
  /// the same text and version as the store, and then runs [request].
  Future<T> _ask<T>(
    SourceLocation target,
    Future<T> Function(LspClient server) request,
  ) async {
    final server = _server();
    if (server == null) throw const ToolUnavailable(serverName);
    _sync.ensureOpen(target.filePath);
    try {
      return await request(server);
    } on LspRequestFailed catch (failure) {
      throw UnsupportedEdit(failure.message);
    }
  }
}
