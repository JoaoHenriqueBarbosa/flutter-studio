import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:studio_core/studio_core.dart' hide SourceNode, TextEdit;
import 'package:studio_protocol/studio_protocol.dart';

import '../support/fake_analysis_server.dart';

void main() {
  group('StudioService', () {
    late Directory project;
    late String filePath;
    late DocumentStore store;
    late DocumentSync sync;
    late SelectionController selection;
    late FakeAnalysisServer server;
    late EditPipeline pipeline;
    late StudioService service;
    late SourceTrees trees;
    var isServerRunning = true;

    WidgetRef reference({int documentVersion = 1, String? uri}) => WidgetRef(
      uri: uri ?? '${Uri.file(filePath)}',
      position: const Position(line: 0, character: 0),
      documentVersion: documentVersion,
    );

    Matcher throwsFault(StudioErrorCode code, Object? data) => throwsA(
      isA<StudioFault>()
          .having((fault) => fault.code, 'code', code)
          .having((fault) => fault.data, 'data', data),
    );

    setUp(() {
      project = Directory.systemTemp.createTempSync('studio_service_test');
      filePath = path.join(project.path, 'main.dart');
      File(filePath).writeAsStringSync("Text('Hi', maxLines: 2)\n");
      isServerRunning = true;
      store = DocumentStore(project.path);
      sync = DocumentSync(store);
      selection = SelectionController(store);
      server = FakeAnalysisServer(
        applyEdit: (edit) => pipeline.applyServerEdit(edit),
      );
      sync.attach(server.client);
      LspClient? currentServer() => isServerRunning ? server.client : null;
      trees = SourceTrees(store, sync)..attach(server.client);
      final reader = WidgetReader(sync, trees, currentServer);
      pipeline = EditPipeline(
        store,
        reader,
        server: currentServer,
        requestReload: () => false,
      );
      service = StudioService(store, selection, pipeline, reader);
      server
        ..editableArguments = {
          'arguments': [
            {
              'name': 'data',
              'type': 'string',
              'value': 'Hi',
              'hasArgument': true,
            },
            {
              'name': 'maxLines',
              'type': 'int',
              'value': 2,
              'hasArgument': true,
              'documentation': 'Lines.',
            },
            {
              'name': 'softWrap',
              'type': 'bool',
              'value': true,
              'defaultValue': true,
            },
            {
              'name': 'style',
              'type': 'TextStyle',
              'displayValue': 'theme.title',
              'hasArgument': true,
              'isEditable': false,
            },
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
                      'start': {'line': 0, 'character': 21},
                      'end': {'line': 0, 'character': 22},
                    },
                    'newText': '3',
                  },
                ],
              },
            ],
          },
        };
    });

    tearDown(() async {
      await trees.dispose();
      await selection.dispose();
      await sync.dispose();
      await server.close();
      await store.dispose();
      project.deleteSync(recursive: true);
    });

    // Verifies: FR-API-001
    test('reports the version of the contract', () async {
      expect((await service.getVersion()).version, StudioContract.version);
    });

    // Verifies: FR-API-001, FR-INS-003
    test('selects a widget and reports the selection', () async {
      expect(await service.getSelection(), isNull);

      final selected = await service.select(target: reference());

      expect(selected, reference());
      expect(await service.getSelection(), reference());
    });

    // Verifies: FR-API-001, FR-PRP-001
    test('lists the properties with their expressions', () async {
      final properties = await service.getProperties(target: reference());

      expect(properties, const [
        Property(
          name: 'data',
          type: 'string',
          expression: Expression(source: "'Hi'"),
          isSet: true,
          isEditable: true,
        ),
        Property(
          name: 'maxLines',
          type: 'int',
          expression: Expression(source: '2'),
          isSet: true,
          isEditable: true,
          documentation: 'Lines.',
        ),
        Property(
          name: 'softWrap',
          type: 'bool',
          defaultValue: Expression(source: 'true'),
          isSet: false,
          isEditable: true,
        ),
        Property(
          name: 'style',
          type: 'TextStyle',
          expression: Expression(source: 'theme.title'),
          isSet: true,
          isEditable: false,
        ),
      ]);
    });

    // Verifies: FR-API-001, FR-PRP-003
    test('sets a property and reports what changed', () async {
      final result = await service.setProperty(
        target: reference(),
        name: 'maxLines',
        value: const Expression(source: '3'),
      );

      final uri = '${Uri.file(filePath)}';
      expect(File(filePath).readAsStringSync(), "Text('Hi', maxLines: 3)\n");
      expect(
        result,
        EditResult(
          applied: true,
          changes: [
            TextDocumentEdit(
              uri: uri,
              edits: const [
                TextEdit(
                  range: Range(
                    start: Position(line: 0, character: 21),
                    end: Position(line: 0, character: 22),
                  ),
                  newText: '3',
                ),
              ],
            ),
          ],
          documentVersions: {uri: 2},
          reload: ReloadKind.none,
        ),
      );
    });

    // Verifies: FR-API-001, FR-DOC-005, FR-DOC-006
    test('undoes and redoes through the service', () async {
      await service.setProperty(
        target: reference(),
        name: 'maxLines',
        value: const Expression(source: '3'),
      );

      final undone = await service.undo();
      expect(File(filePath).readAsStringSync(), "Text('Hi', maxLines: 2)\n");
      expect(undone.applied, isTrue);
      expect(undone.documentVersions, {'${Uri.file(filePath)}': 3});

      expect((await service.redo()).applied, isTrue);
      expect((await service.redo()).applied, isFalse);
    });

    // Verifies: FR-API-001, FR-INS-002
    test('returns the source tree with a reference in each node', () async {
      final tree = service.getSourceTree(uri: '${Uri.file(filePath)}');
      await server.settled;
      server.publishOutline(filePath, {
        'range': {
          'start': {'line': 0, 'character': 0},
          'end': {'line': 1, 'character': 0},
        },
        'children': [
          {
            'range': {
              'start': {'line': 0, 'character': 0},
              'end': {'line': 0, 'character': 23},
            },
            'className': 'Text',
            'children': <Object?>[],
          },
        ],
      });

      expect(await tree, [
        SourceNode(ref: reference(), className: 'Text', children: const []),
      ]);
    });

    // Verifies: NFR-SEC-003
    test('refuses the source tree of a file outside the project', () async {
      await expectLater(
        service.getSourceTree(uri: 'file:///etc/hosts'),
        throwsFault(StudioErrorCode.notInProject, 'file:///etc/hosts'),
      );
    });

    // Verifies: FR-API-001, FR-STR-001
    test('tells which structural edits the widget accepts', () async {
      server.codeActions = [
        for (final kind in [
          'refactor.flutter.wrap.generic',
          'refactor.flutter.wrap.center',
          'refactor.flutter.wrap.sizedBox',
          'refactor.flutter.move.down',
          'refactor.flutter.swap.withParent',
        ])
          {
            'kind': kind,
            'title': kind,
            'edit': {'documentChanges': <Object?>[]},
          },
      ];

      final options = await service.getStructureOptions(target: reference());

      expect(
        options,
        const StructureOptions(
          wrappers: [
            WidgetSpec(
              libraryUri: 'package:flutter/widgets.dart',
              className: 'Center',
            ),
            WidgetSpec(
              libraryUri: 'package:flutter/widgets.dart',
              className: 'SizedBox',
            ),
          ],
          canRemove: false,
          canMoveUp: false,
          canMoveDown: true,
          canSwapWithParent: true,
          canSwapWithChild: false,
        ),
      );
    });

    // Verifies: FR-API-001, FR-STR-001
    test('applies each structural edit as the assist of its kind', () async {
      Future<EditResult> Function() offering(
        String kind,
        Future<EditResult> Function() operation,
      ) => () {
        server.codeActions = [
          {
            'kind': kind,
            'title': kind,
            'edit': {'documentChanges': <Object?>[]},
          },
        ];
        return operation();
      };
      final operations = [
        offering(
          'refactor.flutter.wrap.padding',
          () => service.wrapWidget(
            target: reference(),
            wrapper: const WidgetSpec(
              libraryUri: 'package:flutter/widgets.dart',
              className: 'Padding',
            ),
          ),
        ),
        offering(
          'refactor.flutter.removeWidget',
          () => service.removeWidget(target: reference(), keepChildren: true),
        ),
        offering(
          'refactor.flutter.move.up',
          () => service.reorderWidget(
            target: reference(),
            direction: MoveDirection.up,
          ),
        ),
        offering(
          'refactor.flutter.swap.withChild',
          () => service.swapWidget(
            target: reference(),
            partner: SwapPartner.child,
          ),
        ),
      ];

      for (final operation in operations) {
        // An assist with an empty edit is accepted and changes nothing.
        expect((await operation()).reload, ReloadKind.none);
      }
    });

    // Verifies: FR-API-001, FR-STR-001
    test('refuses a structural edit that the widget does not accept', () {
      expect(
        service.swapWidget(target: reference(), partner: SwapPartner.parent),
        throwsFault(
          StudioErrorCode.unsupportedTarget,
          'The widget does not accept refactor.flutter.swap.withParent.',
        ),
      );
      expect(
        () => service.removeWidget(target: reference(), keepChildren: false),
        throwsFault(StudioErrorCode.unsupportedTarget, isA<String>()),
      );
      expect(
        () => service.wrapWidget(
          target: reference(),
          wrapper: const WidgetSpec(
            libraryUri: 'package:other/other.dart',
            className: 'Card',
          ),
        ),
        throwsFault(StudioErrorCode.unsupportedTarget, isA<String>()),
      );
    });

    // Verifies: FR-API-001
    test('refuses a reference to an old version of the document', () async {
      final stale = reference(documentVersion: 9);

      await expectLater(
        service.select(target: stale),
        throwsFault(StudioErrorCode.staleDocument, 1),
      );
      await expectLater(
        service.getProperties(target: stale),
        throwsFault(StudioErrorCode.staleDocument, 1),
      );
      await expectLater(
        service.setProperty(target: stale, name: 'maxLines', value: null),
        throwsFault(StudioErrorCode.staleDocument, 1),
      );
    });

    // Verifies: NFR-SEC-003
    test('refuses a target outside the project and touches no file', () async {
      for (final uri in ['file:///etc/hosts', 'https://example.com/a.dart']) {
        await expectLater(
          service.setProperty(
            target: reference(uri: uri),
            name: 'maxLines',
            value: const Expression(source: '3'),
          ),
          throwsFault(StudioErrorCode.notInProject, uri),
        );
      }

      expect(server.editRequests, isEmpty);
    });

    // Verifies: FR-API-001
    test('refuses an edit that the target does not accept', () async {
      await expectLater(
        service.setProperty(
          target: reference(),
          name: 'missing',
          value: const Expression(source: 'null'),
        ),
        throwsFault(
          StudioErrorCode.unsupportedTarget,
          'The widget has no argument missing.',
        ),
      );
    });

    // Verifies: FR-API-001, NFR-REL-002
    test('reports the analysis server that is down', () async {
      isServerRunning = false;

      await expectLater(
        service.getProperties(target: reference()),
        throwsFault(StudioErrorCode.toolchainUnavailable, 'analysis-server'),
      );
    });
  });
}
