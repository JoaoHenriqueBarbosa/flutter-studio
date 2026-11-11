import '../document/edit_failure.dart';
import '../document/source_location.dart';
import '../lsp/document_sync.dart';
import '../lsp/editable_argument.dart';
import '../lsp/lsp_client.dart';
import '../lsp/lsp_request_failed.dart';

/// Reads from the analysis server the parameters of the constructor that
/// creates a widget.
final class ArgumentReader {
  /// Creates a reader that opens documents through [_sync].
  ///
  /// [_server] returns the current client of the analysis server, or `null`
  /// while the server is not running.
  const ArgumentReader(this._sync, this._server);

  /// Name of the analysis server in a [ToolUnavailable].
  static const serverName = 'analysis-server';

  final DocumentSync _sync;

  final LspClient? Function() _server;

  /// Completes with the parameters of the constructor called at [target].
  ///
  /// The document is opened in the server first, so that the server reads
  /// the same text and version as the store. Throws [ToolUnavailable] while
  /// the server is down and [UnsupportedEdit] when [target] does not create
  /// a widget.
  Future<List<EditableArgument>> read(SourceLocation target) async {
    final server = _server();
    if (server == null) throw const ToolUnavailable(serverName);
    _sync.ensureOpen(target.filePath);
    try {
      final arguments = await server.editableArguments(target);
      if (arguments != null) return arguments;
    } on LspRequestFailed catch (failure) {
      throw UnsupportedEdit(failure.message);
    }
    throw const UnsupportedEdit('No widget is created at the position.');
  }
}
