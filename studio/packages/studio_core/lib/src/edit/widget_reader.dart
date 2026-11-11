import '../document/edit_failure.dart';
import '../document/source_location.dart';
import '../lsp/document_sync.dart';
import '../lsp/editable_argument.dart';
import '../lsp/lsp_client.dart';
import '../lsp/lsp_request_failed.dart';
import '../lsp/server_assist.dart';

/// Reads from the analysis server what it knows about the widget created
/// at a location.
final class WidgetReader {
  /// Creates a reader that opens documents through [_sync].
  ///
  /// [_server] returns the current client of the analysis server, or `null`
  /// while the server is not running.
  const WidgetReader(this._sync, this._server);

  /// Name of the analysis server in a [ToolUnavailable].
  static const serverName = 'analysis-server';

  final DocumentSync _sync;

  final LspClient? Function() _server;

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
