import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/studio_core.dart';
import 'package:studio_protocol/studio_protocol.dart' show Scene;

void main() {
  group('ScreenshotFrameTransport', () {
    late HttpServer server;
    late List<String> requestPaths;
    Map<String, Object?> answers = const {};

    /// Serves a VM Service that answers each method with its entry in
    /// [answers], and with an error when the method has none.
    setUp(() async {
      requestPaths = [];
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        requestPaths.add(request.uri.path);
        final socket = await WebSocketTransformer.upgrade(request);
        socket.listen((data) {
          final Object? call = jsonDecode(data as String);
          if (call case {'id': final Object? id, 'method': final String name}) {
            final result = answers[name];
            socket.add(
              jsonEncode({
                'jsonrpc': '2.0',
                'id': id,
                'result': ?result,
                if (result == null)
                  'error': {'code': -32601, 'message': 'Unknown method.'},
              }),
            );
          }
        });
      });
    });

    tearDown(() => server.close(force: true));

    Future<ScreenshotFrameTransport> connect() =>
        ScreenshotFrameTransport.connect(
          Uri.parse('http://127.0.0.1:${server.port}/secret=/'),
        );

    const screenshot = {'type': 'Screenshot', 'screenshot': 'iVBORw=='};

    // Verifies: FR-CNV-001
    test('asks the engine for a screenshot and decodes the image', () async {
      answers = {'_flutter.screenshot': screenshot};
      final transport = await connect();
      addTearDown(transport.close);

      final captured = await transport.capture();

      expect(captured?.pngBytes, [137, 80, 78, 71]);
      expect(captured?.scene, isNull);
      expect(requestPaths, ['/secret=/ws']);
    });

    // Verifies: FR-CNV-006
    test('brings the scene of the design agent with the image', () async {
      const scene = Scene(
        width: 800,
        height: 600,
        devicePixelRatio: 3,
        elements: [],
      );
      answers = {
        '_flutter.screenshot': screenshot,
        'getVM': {
          'type': 'VM',
          'isolates': [
            {'type': '@Isolate', 'id': 'isolates/1', 'name': 'main'},
          ],
        },
        'ext.studio.agent.scene': scene.toJson(),
      };
      final transport = await connect();
      addTearDown(transport.close);

      expect((await transport.capture())?.scene, scene);
    });

    // Verifies: FR-CNV-001
    test('gives no image when the engine refuses', () async {
      answers = const {};
      final transport = await connect();
      addTearDown(transport.close);

      expect(await transport.capture(), isNull);
    });
  });
}
