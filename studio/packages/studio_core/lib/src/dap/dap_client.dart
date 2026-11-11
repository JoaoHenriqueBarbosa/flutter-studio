import 'dart:async';
import 'dart:convert';

import 'package:stream_channel/stream_channel.dart';

import 'dap_request_failed.dart';

/// Client of the Flutter debug adapter over the Debug Adapter Protocol
/// (IR-002).
///
/// An Adapter in the role of Gateway: JSON stays inside this class
/// (CS-DSN-004). One client drives one run of the app.
final class DapClient {
  /// Creates a client that talks over [channel], one JSON text per message.
  DapClient(StreamChannel<String> channel) : _sink = channel.sink {
    _subscription = channel.stream.listen(_handleMessage, onDone: _handleDone);
  }

  final StreamSink<String> _sink;

  late final StreamSubscription<String> _subscription;

  final _pending = <int, Completer<void>>{};

  final _commands = <int, String>{};

  final _output = StreamController<String>.broadcast();

  final _adapterReady = Completer<void>();

  final _vmServiceUri = Completer<Uri>();

  final _terminated = Completer<void>();

  var _lastSequence = 0;

  /// Text that the app and the tool write while the app runs (FR-RUN-003).
  Stream<String> get output => _output.stream;

  /// Address of the VM Service of the app, once the app has started.
  Future<Uri> get vmServiceUri => _vmServiceUri.future;

  /// Completes when the run ends, by request or because the app exited.
  Future<void> get terminated => _terminated.future;

  /// Builds and starts the project at [projectPath] on the device
  /// [deviceId], in debug mode. [toolArguments] are extra arguments for the
  /// `flutter` tool.
  ///
  /// Completes when the adapter accepts the launch. The app is running only
  /// when [vmServiceUri] completes. Throws [DapRequestFailed] when the
  /// adapter refuses.
  Future<void> launch({
    required String projectPath,
    required String deviceId,
    List<String> toolArguments = const [],
  }) async {
    await _request('initialize', {'clientID': 'studio', 'adapterID': 'dart'});
    final launched = _request('launch', {
      'cwd': projectPath,
      'program': 'lib/main.dart',
      'toolArgs': ['-d', deviceId, ...toolArguments],
    });
    await _adapterReady.future;
    await _request('configurationDone');
    await launched;
  }

  /// Asks the app to reload the code that changed on disk.
  Future<void> hotReload() => _request('hotReload');

  /// Asks the app to restart with the code on disk, losing its state.
  Future<void> hotRestart() => _request('hotRestart');

  /// Asks the adapter to end the run. [terminated] completes afterwards.
  Future<void> terminate() => _request('terminate');

  /// Stops listening to the adapter and closes the channel.
  Future<void> close() async {
    await _subscription.cancel();
    await _sink.close();
    _handleDone();
  }

  Future<void> _request(String command, [Map<String, Object?>? arguments]) {
    final sequence = ++_lastSequence;
    final completer = _pending[sequence] = Completer<void>();
    _commands[sequence] = command;
    _sink.add(
      jsonEncode({
        'seq': sequence,
        'type': 'request',
        'command': command,
        'arguments': ?arguments,
      }),
    );
    return completer.future;
  }

  void _handleMessage(String text) {
    final Object? message = jsonDecode(text);
    switch (message) {
      case {'type': 'response', 'request_seq': final int sequence}:
        _completeRequest(sequence, message);
      case {'type': 'event', 'event': final String event}:
        _handleEvent(event, message['body']);
    }
  }

  void _completeRequest(int sequence, Map<Object?, Object?> response) {
    final completer = _pending.remove(sequence);
    final command = _commands.remove(sequence);
    if (completer == null || command == null) return;
    if (response['success'] == true) {
      completer.complete();
    } else {
      completer.completeError(
        DapRequestFailed(command, '${response['message']}'),
      );
    }
  }

  void _handleEvent(String event, Object? body) {
    switch ((event, body)) {
      case ('initialized', _) when !_adapterReady.isCompleted:
        _adapterReady.complete();
      case ('output', {'output': final String text}):
        _output.add(text);
      case ('dart.debuggerUris', {'vmServiceUri': final String uri})
          when !_vmServiceUri.isCompleted:
        _vmServiceUri.complete(Uri.parse(uri));
      case ('terminated' || 'exited', _):
        _handleDone();
    }
  }

  void _handleDone() {
    if (!_terminated.isCompleted) _terminated.complete();
    if (!_output.isClosed) unawaited(_output.close());
  }
}
