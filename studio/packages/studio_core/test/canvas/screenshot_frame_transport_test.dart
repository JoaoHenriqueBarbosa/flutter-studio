import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/studio_core.dart';

void main() {
  group('ScreenshotFrameTransport', () {
    late HttpServer server;
    late List<String> requestPaths;
    Map<String, Object?> answer = const {};

    /// Serves a VM Service that answers every call with [answer].
    setUp(() async {
      requestPaths = [];
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        requestPaths.add(request.uri.path);
        final socket = await WebSocketTransformer.upgrade(request);
        socket.listen((data) {
          final Object? call = jsonDecode(data as String);
          if (call case {'id': final Object? id}) {
            socket.add(jsonEncode({'jsonrpc': '2.0', 'id': id, ...answer}));
          }
        });
      });
    });

    tearDown(() => server.close(force: true));

    Future<ScreenshotFrameTransport> connect() =>
        ScreenshotFrameTransport.connect(
          Uri.parse('http://127.0.0.1:${server.port}/secret=/'),
        );

    // Verifies: FR-CNV-001
    test('asks the engine for a screenshot and decodes the image', () async {
      answer = {
        'result': {
          'type': 'Screenshot',
          'screenshot': base64Encode([137, 80, 78, 71]),
        },
      };
      final transport = await connect();
      addTearDown(transport.close);

      expect(await transport.capture(), [137, 80, 78, 71]);
      expect(requestPaths, ['/secret=/ws']);
    });

    // Verifies: FR-CNV-001
    test('gives no image when the engine refuses', () async {
      answer = {
        'error': {'code': -32000, 'message': 'No frame.'},
      };
      final transport = await connect();
      addTearDown(transport.close);

      expect(await transport.capture(), isNull);
    });
  });
}
