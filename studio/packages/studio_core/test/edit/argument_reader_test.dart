import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:studio_core/studio_core.dart';

import '../support/fake_analysis_server.dart';

void main() {
  group('ArgumentReader', () {
    late Directory project;
    late DocumentStore store;
    late DocumentSync sync;
    late FakeAnalysisServer server;
    late SourceLocation target;
    var isServerRunning = true;

    setUp(() {
      project = Directory.systemTemp.createTempSync('argument_reader_test');
      final filePath = path.join(project.path, 'main.dart');
      File(filePath).writeAsStringSync('Column()\n');
      target = (filePath: filePath, position: (line: 0, character: 0));
      isServerRunning = true;
      store = DocumentStore(project.path);
      server = FakeAnalysisServer(applyEdit: (edit) async => false);
      sync = DocumentSync(store)..attach(server.client);
    });

    tearDown(() async {
      await sync.dispose();
      await server.close();
      await store.dispose();
      project.deleteSync(recursive: true);
    });

    ArgumentReader reader() =>
        ArgumentReader(sync, () => isServerRunning ? server.client : null);

    // Verifies: FR-PRP-001
    test('opens the document and reads the arguments', () async {
      server.editableArguments = {
        'arguments': [
          {'name': 'spacing', 'type': 'double'},
        ],
      };

      final arguments = await reader().read(target);

      expect(arguments.single.name, 'spacing');
      expect(server.documentEvents.single.$1, 'textDocument/didOpen');
    });

    // Verifies: FR-PRP-001
    test('refuses a position that creates no widget', () async {
      await expectLater(reader().read(target), throwsA(isA<UnsupportedEdit>()));
    });

    // Verifies: NFR-REL-002
    test('refuses to read while the analysis server is down', () async {
      isServerRunning = false;

      await expectLater(reader().read(target), throwsA(isA<ToolUnavailable>()));
    });
  });
}
