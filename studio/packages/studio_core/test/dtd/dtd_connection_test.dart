import 'dart:convert';
import 'dart:io';

import 'package:dtd/dtd.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/studio_core.dart';

void main() {
  // Verifies: IR-003
  test('DtdConnection announces the active location to the tools', () async {
    final daemon = await Process.start('dart', ['tooling-daemon', '--machine']);
    addTearDown(daemon.kill);
    final handshake = await daemon.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .first;
    final uri = Uri.parse(
      ((jsonDecode(handshake) as Map<String, Object?>)['tooling_daemon_details']
              as Map<String, Object?>)['uri']
          as String,
    );
    final tool = await DartToolingDaemon.connect(uri);
    addTearDown(tool.close);
    await tool.streamListen('Editor');
    final connection = await DtdConnection.connect(uri);
    addTearDown(connection.close);
    final event = tool.onEvent('Editor').first;

    await connection.postActiveLocation(
      filePath: '/work/sample_app/lib/main.dart',
      position: (line: 90, character: 18),
    );

    final received = await event;
    expect(received.kind, 'activeLocationChanged');
    expect(received.data, {
      'textDocument': {
        'uri': 'file:///work/sample_app/lib/main.dart',
        'version': null,
      },
      'selections': [
        {
          'active': {'line': 90, 'character': 18},
          'anchor': {'line': 90, 'character': 18},
        },
      ],
    });
  });
}
