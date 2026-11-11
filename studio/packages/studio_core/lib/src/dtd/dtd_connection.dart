import 'package:dtd/dtd.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:studio_protocol/studio_protocol.dart';

import '../document/text_edit.dart';

/// Connection of the shell with the Dart Tooling Daemon (IR-003).
///
/// An Adapter in the role of Gateway over the `dtd` package.
final class DtdConnection {
  DtdConnection._(this._daemon, this.uri);

  /// Stream on which an editor announces its state to the tools.
  static const _editorStream = 'Editor';

  static const _activeLocationChangedKind = 'activeLocationChanged';

  final DartToolingDaemon _daemon;

  /// Address of the daemon.
  final Uri uri;

  /// Completes when the connection with the daemon ends.
  Future<void> get done => _daemon.done;

  /// Connects to the daemon at [uri].
  static Future<DtdConnection> connect(Uri uri) async =>
      DtdConnection._(await DartToolingDaemon.connect(uri), uri);

  /// Announces on the `Editor` stream that the active location is
  /// [position] in the file at [filePath], in the document at
  /// [documentVersion].
  Future<void> postActiveLocation({
    required String filePath,
    required DocumentPosition position,
    required int documentVersion,
  }) {
    final cursor = {'line': position.line, 'character': position.character};
    return _post(_editorStream, _activeLocationChangedKind, {
      'textDocument': {
        'uri': '${Uri.file(filePath)}',
        'version': documentVersion,
      },
      'selections': [
        {'active': cursor, 'anchor': cursor},
      ],
    });
  }

  /// Registers the `Studio` service in the daemon, served by [api]
  /// (IR-003).
  ///
  /// Completes when every method is registered. A result travels in the
  /// envelope that the contract names, and a [StudioFault] travels as a
  /// JSON-RPC error with the code, the name and the data of the fault.
  Future<void> serveStudio(StudioApi api) async {
    final dispatcher = StudioDispatcher(api);
    for (final method in StudioMethod.values) {
      await _daemon.registerService(
        StudioContract.serviceName,
        method.name,
        (parameters) => _serve(dispatcher, method, parameters),
      );
    }
  }

  /// Posts [event] with [data], in JSON form, on the stream of the `Studio`
  /// service.
  Future<void> postStudioEvent(StudioEvent event, Map<String, Object?> data) =>
      _post(StudioContract.streamName, event.name, data);

  /// Closes the connection.
  Future<void> close() => _daemon.close();

  /// Posts an event, and completes without effect when the connection
  /// closes before the daemon confirms it: nobody is left to hear it.
  Future<void> _post(
    String stream,
    String kind,
    Map<String, Object?> data,
  ) async {
    try {
      await _daemon.postEvent(stream, kind, data);
    } on StateError {
      return;
    }
  }

  Future<Map<String, Object?>> _serve(
    StudioDispatcher dispatcher,
    StudioMethod method,
    Parameters parameters,
  ) async {
    final Object? value = parameters.value;
    try {
      final result = await dispatcher.dispatch(method, switch (value) {
        final Map<Object?, Object?> named => named.cast<String, Object?>(),
        _ => const {},
      });
      return {
        'type': StudioContract.resultType,
        StudioContract.resultKey: result,
      };
    } on StudioFault catch (fault) {
      throw RpcException(fault.code.code, fault.code.message, data: fault.data);
    } on FormatException catch (exception) {
      throw RpcException.invalidParams(exception.message);
    }
  }
}
