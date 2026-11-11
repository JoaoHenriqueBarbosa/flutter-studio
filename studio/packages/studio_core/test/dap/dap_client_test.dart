import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:studio_core/studio_core.dart';

/// Plays the debug adapter: records the requests and answers each one, the
/// way the Flutter adapter orders its messages.
final class _FakeAdapter {
  _FakeAdapter(this._channel, {this.failingCommand}) {
    _channel.stream.listen(_handle);
  }

  final StreamChannel<String> _channel;

  final String? failingCommand;

  final requests = <Map<String, Object?>>[];

  void emit(String event, [Map<String, Object?>? body]) {
    _channel.sink.add(
      jsonEncode({'type': 'event', 'event': event, 'body': ?body}),
    );
  }

  void _handle(String text) {
    final request = jsonDecode(text) as Map<String, Object?>;
    requests.add(request);
    final command = request['command'];
    // The real adapter answers the launch only after configurationDone.
    if (command == 'launch') {
      emit('initialized');
      return;
    }
    _respond(request);
    if (command == 'configurationDone') {
      _respond(requests.firstWhere((sent) => sent['command'] == 'launch'));
    }
  }

  void _respond(Map<String, Object?> request) {
    final failed = request['command'] == failingCommand;
    _channel.sink.add(
      jsonEncode({
        'type': 'response',
        'request_seq': request['seq'],
        'command': request['command'],
        'success': !failed,
        if (failed) 'message': 'No device.',
      }),
    );
  }
}

void main() {
  group('DapClient', () {
    late StreamChannelController<String> controller;
    late DapClient client;

    setUp(() {
      controller = StreamChannelController<String>();
      client = DapClient(controller.local);
    });

    tearDown(() => client.close());

    // Verifies: FR-RUN-001, IR-002
    test('launches the project on the chosen device', () async {
      final adapter = _FakeAdapter(controller.foreign);

      await client.launch(projectPath: '/work/sample_app', deviceId: 'linux');

      expect(
        [for (final request in adapter.requests) request['command']],
        ['initialize', 'launch', 'configurationDone'],
      );
      expect(adapter.requests[1]['arguments'], {
        'cwd': '/work/sample_app',
        'program': 'lib/main.dart',
        'toolArgs': ['-d', 'linux'],
      });
    });

    // Verifies: FR-RUN-001
    test('fails the launch that the adapter refuses', () async {
      _FakeAdapter(controller.foreign, failingCommand: 'launch');

      await expectLater(
        client.launch(projectPath: '/work/sample_app', deviceId: 'none'),
        throwsA(
          isA<DapRequestFailed>().having(
            (failure) => '$failure',
            'message',
            'Request launch failed: No device.',
          ),
        ),
      );
    });

    // Verifies: FR-RUN-001
    test('sends reload, restart and terminate as requests', () async {
      final adapter = _FakeAdapter(controller.foreign);

      await client.hotReload();
      await client.hotRestart();
      await client.terminate();

      expect(
        [for (final request in adapter.requests) request['command']],
        ['hotReload', 'hotRestart', 'terminate'],
      );
    });

    // Verifies: FR-RUN-003
    test('publishes the output of the app', () async {
      final adapter = _FakeAdapter(controller.foreign);
      final published = expectLater(client.output, emits('Hello.\n'));

      adapter.emit('output', {'category': 'stdout', 'output': 'Hello.\n'});

      await published;
    });

    // Verifies: FR-RUN-001
    test('reports the VM Service address and the end of the run', () async {
      final adapter = _FakeAdapter(controller.foreign)
        ..emit('dart.debuggerUris', {'vmServiceUri': 'ws://127.0.0.1:1/ws'});

      expect(await client.vmServiceUri, Uri.parse('ws://127.0.0.1:1/ws'));

      adapter.emit('terminated');

      await client.terminated;
    });
  });
}
