import 'dart:convert';
import 'dart:io';

import 'package:dtd/dtd.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:studio_core/studio_core.dart';
import 'package:studio_protocol/studio_protocol.dart';

/// A [StudioApi] that selects what it is asked to, and refuses to undo.
final class _SampleApi implements StudioApi {
  @override
  Future<WidgetRef> select({required WidgetRef target}) async => target;

  @override
  Future<WidgetRef?> getSelection() async => null;

  @override
  Future<EditResult> undo() =>
      throw const StudioFault(StudioErrorCode.staleDocument, data: 7);

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('DtdConnection', () {
    late Process daemon;
    late DartToolingDaemon tool;
    late DtdConnection connection;

    setUp(() async {
      daemon = await Process.start('dart', ['tooling-daemon', '--machine']);
      final handshake = await daemon.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first;
      final Object? details = jsonDecode(handshake);
      if (details case {'tooling_daemon_details': {'uri': final String uri}}) {
        tool = await DartToolingDaemon.connect(Uri.parse(uri));
        connection = await DtdConnection.connect(Uri.parse(uri));
      } else {
        fail('Unexpected handshake: $handshake');
      }
    });

    tearDown(() async {
      await connection.close();
      await tool.close();
      daemon.kill();
    });

    // Verifies: IR-003
    test('announces the active location on the Editor stream', () async {
      await tool.streamListen('Editor');
      final event = tool.onEvent('Editor').first;

      await connection.postActiveLocation(
        filePath: '/work/sample_app/lib/main.dart',
        position: (line: 90, character: 18),
        documentVersion: 4,
      );

      final received = await event;
      expect(received.kind, 'activeLocationChanged');
      expect(received.data, {
        'textDocument': {
          'uri': 'file:///work/sample_app/lib/main.dart',
          'version': 4,
        },
        'selections': [
          {
            'active': {'line': 90, 'character': 18},
            'anchor': {'line': 90, 'character': 18},
          },
        ],
      });
    });

    // Verifies: IR-003, FR-API-001
    test('serves the Studio service to another client of the daemon', () async {
      await connection.serveStudio(_SampleApi());
      final target = {
        'uri': 'file:///work/sample_app/lib/main.dart',
        'position': {'line': 11, 'character': 14},
        'documentVersion': 1,
      };

      final selected = await tool.call(
        'Studio',
        'select',
        params: {'target': target},
      );
      final selection = await tool.call('Studio', 'getSelection');

      expect(selected.result, {'type': 'StudioResult', 'result': target});
      expect(selection.result, {'type': 'StudioResult', 'result': null});
    });

    // Verifies: FR-API-001
    test('reports a fault with the code, the name and the data', () async {
      await connection.serveStudio(_SampleApi());

      await expectLater(
        tool.call('Studio', 'undo'),
        throwsA(
          isA<RpcException>()
              .having((exception) => exception.code, 'code', -32001)
              .having(
                (exception) => exception.message,
                'message',
                'StaleDocument',
              )
              .having((exception) => exception.data, 'data', 7),
        ),
      );
    });

    // Verifies: FR-API-001
    test('reports malformed parameters as invalid', () async {
      await connection.serveStudio(_SampleApi());

      await expectLater(
        tool.call('Studio', 'select', params: {'target': 'main.dart'}),
        throwsA(
          isA<RpcException>().having(
            (exception) => exception.code,
            'code',
            -32602,
          ),
        ),
      );
    });

    // Verifies: FR-API-004
    test('posts an event on the Studio stream', () async {
      await tool.streamListen('Studio');
      final event = tool.onEvent('Studio').first;

      await connection.postStudioEvent(
        StudioEvent.selectionChanged,
        const SelectionChanged().toJson(),
      );

      final received = await event;
      expect(received.kind, 'selectionChanged');
      expect(received.data, isEmpty);
    });
  });
}
