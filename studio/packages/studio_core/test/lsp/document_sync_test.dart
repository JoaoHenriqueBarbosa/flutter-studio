import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:studio_core/studio_core.dart';

import '../support/fake_analysis_server.dart';

void main() {
  group('DocumentSync', () {
    late Directory project;
    late String filePath;
    late DocumentStore store;
    late DocumentSync sync;
    late FakeAnalysisServer server;

    WorkspaceEdit insertAtStart(String text) => WorkspaceEdit([
      (
        filePath: filePath,
        edits: [
          (
            range: (
              start: (line: 0, character: 0),
              end: (line: 0, character: 0),
            ),
            newText: text,
          ),
        ],
      ),
    ]);

    setUp(() {
      project = Directory.systemTemp.createTempSync('document_sync_test');
      filePath = path.join(project.path, 'main.dart');
      File(filePath).writeAsStringSync('a\n');
      store = DocumentStore(project.path);
      sync = DocumentSync(store);
      server = FakeAnalysisServer(applyEdit: (edit) async => false);
    });

    tearDown(() async {
      await sync.dispose();
      await server.close();
      await store.dispose();
      project.deleteSync(recursive: true);
    });

    // Verifies: FR-DOC-001
    test('opens a document once and sends each change after that', () async {
      final uri = '${Uri.file(filePath)}';
      sync
        ..attach(server.client)
        ..ensureOpen(filePath)
        ..ensureOpen(filePath);

      await store.apply(insertAtStart('b'));
      await pumpEventQueue();
      await server.settled;

      expect(server.documentEvents, [
        ('textDocument/didOpen', uri, 1),
        ('textDocument/didChange', uri, 2),
      ]);
    });

    // Verifies: FR-DOC-001
    test('sends nothing about a document that was not opened', () async {
      sync.attach(server.client);

      await store.apply(insertAtStart('b'));
      await pumpEventQueue();
      await server.settled;

      expect(server.documentEvents, isEmpty);
    });

    // Verifies: NFR-REL-002
    test('opens the documents again in a server that starts later', () async {
      sync.ensureOpen(filePath);
      await store.apply(insertAtStart('b'));

      sync.attach(server.client);
      await server.settled;

      expect(server.documentEvents, [
        ('textDocument/didOpen', '${Uri.file(filePath)}', 2),
      ]);
    });
  });
}
