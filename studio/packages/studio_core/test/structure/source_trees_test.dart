import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:studio_core/studio_core.dart';

import '../support/fake_analysis_server.dart';
import '../support/sample_outline.dart';

void main() {
  group('SourceTrees', () {
    late Directory project;
    late String filePath;
    late DocumentStore store;
    late DocumentSync sync;
    late FakeAnalysisServer server;
    late SourceTrees trees;

    setUp(() {
      project = Directory.systemTemp.createTempSync('source_trees_test');
      filePath = path.join(project.path, 'page.dart');
      File(filePath).writeAsStringSync(sampleOutlineSource);
      store = DocumentStore(project.path);
      server = FakeAnalysisServer(applyEdit: (edit) async => false);
      sync = DocumentSync(store)..attach(server.client);
      trees = SourceTrees(
        store,
        sync,
        patience: const Duration(milliseconds: 300),
      );
    });

    tearDown(() async {
      await trees.dispose();
      await sync.dispose();
      await server.close();
      await store.dispose();
      project.deleteSync(recursive: true);
    });

    // Verifies: FR-INS-002
    test('opens the file and waits for the outline of its version', () async {
      trees.attach(server.client);

      final tree = trees.treeOf(filePath);
      await server.settled;
      server.publishOutline(filePath, sampleOutline);

      expect((await tree).documentVersion, 1);
      expect((await tree).roots.single.className, 'Center');
      expect(server.documentEvents.single.$1, 'textDocument/didOpen');
      expect(await trees.treeOf(filePath), await tree);
    });

    // Verifies: FR-INS-002
    test('does not answer with the tree of an older version', () async {
      trees.attach(server.client);
      final first = trees.treeOf(filePath);
      await server.settled;
      server.publishOutline(filePath, sampleOutline);
      await first;

      await store.apply(
        WorkspaceEdit([
          (
            filePath: filePath,
            edits: [
              (
                range: (
                  start: (line: 0, character: 0),
                  end: (line: 0, character: 0),
                ),
                newText: '// Edited.\n',
              ),
            ],
          ),
        ]),
      );

      await expectLater(
        trees.treeOf(filePath),
        throwsA(isA<ToolUnavailable>()),
      );
    });

    // Verifies: NFR-REL-002
    test('refuses to read while no analysis server is attached', () async {
      await expectLater(
        trees.treeOf(filePath),
        throwsA(isA<ToolUnavailable>()),
      );
    });

    // Verifies: FR-INS-002
    test('ignores the outline of a file that the store has not read', () async {
      trees.attach(server.client);
      final changes = <SourceTree>[];
      final subscription = trees.changes.listen(changes.add);
      addTearDown(subscription.cancel);

      server.publishOutline('/elsewhere/other.dart', sampleOutline);
      await server.settled;
      await pumpEventQueue();

      expect(changes, isEmpty);
    });
  });
}
