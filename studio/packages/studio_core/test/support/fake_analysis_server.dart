import 'dart:async';

import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:studio_core/studio_core.dart';

/// An analysis server that lives in the test: it records the documents it
/// is sent and answers the two argument methods from what the test sets.
final class FakeAnalysisServer {
  /// Creates the server and the [client] connected to it. Edits that the
  /// server asks for go to [applyEdit].
  FakeAnalysisServer({required ApplyEdit applyEdit}) {
    final controller = StreamChannelController<String>();
    _peer = Peer(controller.foreign)
      ..registerMethod('textDocument/didOpen', _recordDocument)
      ..registerMethod('textDocument/didChange', _recordDocument)
      ..registerMethod(
        'dart/textDocument/editableArguments',
        (Parameters _) => editableArguments,
      )
      ..registerMethod('dart/textDocument/editArgument', _handleEditArgument)
      ..registerMethod(
        'textDocument/codeAction',
        (Parameters _) => codeActions,
      );
    unawaited(_peer.listen());
    client = LspClient(controller.local, applyEdit: applyEdit);
  }

  late final Peer _peer;

  /// The client connected to this server.
  late final LspClient client;

  /// Each `didOpen` and `didChange` received: method, URI and version.
  final documentEvents = <(String, String, int)>[];

  /// Parameters of each `editArgument` received.
  final editRequests = <Object?>[];

  /// Result of `editableArguments`.
  Object? editableArguments;

  /// Parameters of the `workspace/applyEdit` that the server sends when it
  /// receives an `editArgument`, or `null` to send none.
  Map<String, Object?>? editToApply;

  /// Result of `textDocument/codeAction`.
  Object? codeActions = const <Object?>[];

  /// Message of the error that `editArgument` answers, or `null` to succeed.
  String? editError;

  /// Publishes [outline] as the Flutter Outline of the file at [filePath].
  void publishOutline(String filePath, Map<String, Object?> outline) =>
      _peer.sendNotification('dart/textDocument/publishFlutterOutline', {
        'uri': '${Uri.file(filePath)}',
        'outline': outline,
      });

  /// Completes when the server has handled everything sent so far.
  Future<void> get settled => client.editableArguments((
    filePath: '/settled',
    position: (line: 0, character: 0),
  ));

  /// Closes both ends.
  Future<void> close() async {
    await client.close();
    await _peer.close();
  }

  void _recordDocument(Parameters parameters) {
    documentEvents.add((
      parameters.method,
      parameters['textDocument']['uri'].asString,
      parameters['textDocument']['version'].asInt,
    ));
  }

  Future<Object?> _handleEditArgument(Parameters parameters) async {
    editRequests.add(parameters.value);
    final message = editError;
    if (message != null) throw RpcException(-32000, message);
    final edit = editToApply;
    if (edit != null) await _peer.sendRequest('workspace/applyEdit', edit);
    return null;
  }
}
