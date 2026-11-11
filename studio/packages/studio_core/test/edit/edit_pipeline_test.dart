import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:studio_core/studio_core.dart';
import 'package:studio_protocol/studio_protocol.dart' show Scene;

import '../support/fake_analysis_server.dart';

void main() {
  group('EditPipeline', () {
    late Directory project;
    late String filePath;
    late DocumentStore store;
    late DocumentSync sync;
    late FakeAnalysisServer server;
    late EditPipeline pipeline;
    late SourceTrees trees;
    Scene? runningScene;
    late SourceLocation target;
    var reloadCount = 0;
    var isAppRunning = true;
    var isServerRunning = true;

    setUp(() {
      project = Directory.systemTemp.createTempSync('edit_pipeline_test');
      filePath = path.join(project.path, 'main.dart');
      File(filePath).writeAsStringSync('Column(alignment: .center)\n');
      target = (filePath: filePath, position: (line: 0, character: 0));
      reloadCount = 0;
      isAppRunning = true;
      isServerRunning = true;
      store = DocumentStore(project.path);
      sync = DocumentSync(store);
      server = FakeAnalysisServer(
        applyEdit: (edit) => pipeline.applyServerEdit(edit),
      );
      sync.attach(server.client);
      LspClient? currentServer() => isServerRunning ? server.client : null;
      trees = SourceTrees(store, sync)..attach(server.client);
      pipeline = EditPipeline(
        store,
        WidgetReader(
          sync,
          trees,
          currentServer,
          runningScene: () => runningScene,
        ),
        server: currentServer,
        requestReload: () {
          if (isAppRunning) reloadCount++;
          return isAppRunning;
        },
      );
      server
        ..editableArguments = {
          'arguments': [
            {
              'name': 'alignment',
              'type': 'enum',
              'isEditable': true,
              'options': ['Alignment.end', 'Alignment.center'],
            },
            {'name': 'children', 'type': 'widget', 'isEditable': false},
          ],
        }
        ..editToApply = {
          'edit': {
            'documentChanges': [
              {
                'textDocument': {'uri': '${Uri.file(filePath)}', 'version': 1},
                'edits': [
                  {
                    'range': {
                      'start': {'line': 0, 'character': 18},
                      'end': {'line': 0, 'character': 25},
                    },
                    'newText': '.end',
                  },
                ],
              },
            ],
          },
        };
    });

    tearDown(() async {
      await trees.dispose();
      await sync.dispose();
      await server.close();
      await store.dispose();
      project.deleteSync(recursive: true);
    });

    Future<EditOutcome> setAlignment({
      int documentVersion = 1,
      String? source = 'Alignment.end',
      String name = 'alignment',
    }) => pipeline.setArgument(
      target,
      documentVersion: documentVersion,
      name: name,
      source: source,
    );

    /// Publishes the outline of the file: one `Column` whose argument
    /// `alignment` has its value at characters 18 to 25.
    Future<void> publishOutline() async {
      sync.ensureOpen(filePath);
      await server.settled;
      server.publishOutline(filePath, {
        'range': {
          'start': {'line': 0, 'character': 0},
          'end': {'line': 1, 'character': 0},
        },
        'children': [
          {
            'className': 'Column',
            'range': {
              'start': {'line': 0, 'character': 0},
              'end': {'line': 0, 'character': 26},
            },
            'attributes': [
              {
                'name': 'alignment',
                'valueRange': {
                  'start': {'line': 0, 'character': 18},
                  'end': {'line': 0, 'character': 25},
                },
              },
            ],
          },
        ],
      });
    }

    // Verifies: FR-PRP-008
    test('removes an argument from the code', () async {
      await publishOutline();

      final outcome = await setAlignment(source: null);

      expect(File(filePath).readAsStringSync(), 'Column()\n');
      expect(outcome.isReloadRequested, isTrue);
      expect(server.editRequests, isEmpty);
    });

    // Verifies: FR-PRP-008
    test('changes nothing when the argument to remove is not there', () async {
      await publishOutline();

      final outcome = await setAlignment(name: 'children', source: null);

      expect(outcome.edit, isNull);
      expect(File(filePath).readAsStringSync(), 'Column(alignment: .center)\n');
    });

    // Verifies: FR-PRP-007
    test('writes an expression that is not a literal as text', () async {
      await publishOutline();

      await setAlignment(source: 'widget.alignment');

      expect(
        File(filePath).readAsStringSync(),
        'Column(alignment: widget.alignment)\n',
      );
      expect(server.editRequests, isEmpty);
      expect(store.canUndo.value, isTrue);
    });

    // Verifies: FR-PRP-007
    test('refuses an expression for an argument that is not there', () async {
      await publishOutline();

      await expectLater(
        setAlignment(name: 'children', source: 'buildChildren()'),
        throwsA(isA<UnsupportedEdit>()),
      );
    });

    // Verifies: FR-PRP-003, FR-DOC-002
    test('writes the edit of the server and asks for the reload', () async {
      final outcome = await setAlignment();

      expect(File(filePath).readAsStringSync(), 'Column(alignment: .end)\n');
      expect(outcome.edit?.versions, {filePath: 2});
      expect(outcome.edit?.changes.single.edits.single.newText, '.end');
      expect(outcome.isReloadRequested, isTrue);
      expect(reloadCount, 1);
      expect(server.editRequests.single, {
        'textDocument': {'uri': '${Uri.file(filePath)}', 'version': 1},
        'position': {'line': 0, 'character': 0},
        'edit': {'name': 'alignment', 'newValue': 'Alignment.end'},
      });
      expect(server.documentEvents.first.$1, 'textDocument/didOpen');
    });

    // Verifies: FR-DOC-002
    test('reports that no reload was asked when no app is running', () async {
      isAppRunning = false;

      final outcome = await setAlignment();

      expect(outcome.edit, isNotNull);
      expect(outcome.isReloadRequested, isFalse);
    });

    // Verifies: FR-PRP-003
    test('reports no edit when the server changes nothing', () async {
      server.editToApply = null;

      final outcome = await setAlignment();

      expect(outcome.edit, isNull);
      expect(reloadCount, 0);
    });

    // Verifies: FR-API-001
    test('refuses a version that is not the current one', () async {
      await expectLater(
        setAlignment(documentVersion: 7),
        throwsA(
          isA<StaleDocument>().having(
            (failure) => failure.currentVersion,
            'currentVersion',
            1,
          ),
        ),
      );

      expect(server.editRequests, isEmpty);
    });

    // Verifies: NFR-SEC-003
    test('refuses a file outside the project', () async {
      target = (filePath: '/etc/hosts', position: (line: 0, character: 0));

      await expectLater(setAlignment(), throwsA(isA<EditOutsideProject>()));
    });

    // Verifies: FR-PRP-003
    test('refuses what the widget does not have', () async {
      await expectLater(
        setAlignment(name: 'missing'),
        throwsA(isA<UnsupportedEdit>()),
      );
      server.editableArguments = null;
      await expectLater(setAlignment(), throwsA(isA<UnsupportedEdit>()));

      expect(server.editRequests, isEmpty);
    });

    // Verifies: FR-PRP-003
    test('reports the refusal of the server as an unsupported edit', () async {
      server.editError = 'Not editable here.';

      await expectLater(
        setAlignment(),
        throwsA(
          isA<UnsupportedEdit>().having(
            (failure) => failure.reason,
            'reason',
            'Not editable here.',
          ),
        ),
      );
    });

    // Verifies: NFR-REL-002
    test('refuses to edit while the analysis server is down', () async {
      isServerRunning = false;

      await expectLater(setAlignment(), throwsA(isA<ToolUnavailable>()));
    });

    // Verifies: FR-STR-001
    test('applies an assist that the server offers', () async {
      server.codeActions = [
        {
          'kind': 'refactor.flutter.wrap.center',
          'title': 'Wrap with Center',
          'edit': server.editToApply?['edit'],
        },
      ];

      final outcome = await pipeline.applyAssist(
        target,
        documentVersion: 1,
        assist: WidgetAssist.wrapWith('Center'),
      );

      expect(File(filePath).readAsStringSync(), 'Column(alignment: .end)\n');
      expect(outcome.edit?.versions, {filePath: 2});
      expect(outcome.isReloadRequested, isTrue);
      expect(store.canUndo.value, isTrue);
    });

    // Verifies: FR-STR-001
    test('refuses an assist that the server does not offer', () async {
      await expectLater(
        pipeline.applyAssist(
          target,
          documentVersion: 1,
          assist: WidgetAssist.remove,
        ),
        throwsA(isA<UnsupportedEdit>()),
      );
      await expectLater(
        pipeline.applyAssist(
          target,
          documentVersion: 4,
          assist: WidgetAssist.remove,
        ),
        throwsA(isA<StaleDocument>()),
      );
    });

    // Verifies: FR-DOC-005, FR-DOC-006
    test('undo and redo go through the same line and reload', () async {
      await setAlignment();

      final undone = await pipeline.undo();
      expect(File(filePath).readAsStringSync(), 'Column(alignment: .center)\n');
      expect(undone.edit?.versions, {filePath: 3});

      final redone = await pipeline.redo();
      expect(File(filePath).readAsStringSync(), 'Column(alignment: .end)\n');
      expect(redone.isReloadRequested, isTrue);
      expect(reloadCount, 3);

      expect((await pipeline.redo()).edit, isNull);
    });

    // Verifies: FR-API-001
    test('runs the operations one at a time, in arrival order', () async {
      final first = setAlignment();
      final second = setAlignment();

      await first;
      await expectLater(second, throwsA(isA<StaleDocument>()));
    });

    // Verifies: FR-DOC-001, FR-DOC-002
    test('applies and reloads an edit the server asks for by itself', () async {
      final edit = WorkspaceEdit([
        (
          filePath: filePath,
          edits: [
            (
              range: (
                start: (line: 0, character: 0),
                end: (line: 0, character: 6),
              ),
              newText: 'Row',
            ),
          ],
        ),
      ]);

      expect(await pipeline.applyServerEdit(edit), isTrue);
      expect(File(filePath).readAsStringSync(), 'Row(alignment: .center)\n');
      expect(reloadCount, 1);
    });

    // Verifies: IR-005
    test('tells the server when its edit cannot be applied', () async {
      const outside = WorkspaceEdit([(filePath: '/etc/hosts', edits: [])]);

      expect(await pipeline.applyServerEdit(outside), isFalse);
    });
  });
}
