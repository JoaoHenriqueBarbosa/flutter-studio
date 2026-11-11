import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:studio_core/studio_core.dart';

void main() {
  group('LspClient', () {
    late Peer server;
    late LspClient client;
    late List<WorkspaceEdit> appliedEdits;
    var applyResult = true;

    setUp(() {
      final controller = StreamChannelController<String>();
      appliedEdits = [];
      applyResult = true;
      server = Peer(controller.foreign);
      client = LspClient(
        controller.local,
        applyEdit: (edit) async {
          appliedEdits.add(edit);
          return applyResult;
        },
      );
    });

    tearDown(() async {
      await client.close();
      await server.close();
    });

    // Verifies: IR-001
    test('initializes the server for the project root', () async {
      final requests = <Object?>[];
      final initialized = Completer<void>();
      server
        ..registerMethod('initialize', (Parameters parameters) {
          requests.add(parameters['rootUri'].value);
          requests.add(
            parameters['capabilities']['workspace']['applyEdit'].value,
          );
          return <String, Object?>{};
        })
        ..registerMethod('initialized', (Parameters _) {
          initialized.complete();
        });
      unawaited(server.listen());

      await client.initialize('/work/sample_app');
      await initialized.future;

      expect(requests, ['file:///work/sample_app/', true]);
    });

    // Verifies: FR-PRJ-004
    test('pairs the server with the tooling daemon', () async {
      Object? pairedUri;
      server.registerMethod('dart/connectToDtd', (Parameters parameters) {
        pairedUri = parameters['uri'].value;
      });
      unawaited(server.listen());

      await client.connectToDtd(Uri.parse('ws://127.0.0.1:1234/secret'));

      expect(pairedUri, 'ws://127.0.0.1:1234/secret');
    });

    // Verifies: FR-DOC-001
    test('hands an edit requested by the server to the applier', () async {
      unawaited(server.listen());

      final reply = await server.sendRequest('workspace/applyEdit', {
        'label': 'Edit argument',
        'edit': {
          'documentChanges': [
            {
              'textDocument': {
                'uri': 'file:///work/sample_app/lib/main.dart',
                'version': null,
              },
              'edits': [
                {
                  'newText': '.end',
                  'range': {
                    'start': {'line': 104, 'character': 29},
                    'end': {'line': 104, 'character': 36},
                  },
                },
              ],
            },
          ],
        },
      });

      expect(reply, {'applied': true});
      final fileEdit = appliedEdits.single.fileEdits.single;
      expect(fileEdit.filePath, '/work/sample_app/lib/main.dart');
      expect(fileEdit.edits, [
        (
          range: (
            start: (line: 104, character: 29),
            end: (line: 104, character: 36),
          ),
          newText: '.end',
        ),
      ]);
    });

    // Verifies: FR-DOC-001
    test('reports to the server an edit that was not applied', () async {
      applyResult = false;
      unawaited(server.listen());

      final reply = await server.sendRequest('workspace/applyEdit', {
        'edit': {'documentChanges': <Object?>[]},
      });

      expect(reply, {'applied': false});
    });

    // Verifies: FR-DOC-001
    test('refuses an edit with a part it does not apply', () async {
      unawaited(server.listen());

      final reply = await server.sendRequest('workspace/applyEdit', {
        'edit': {
          'documentChanges': [
            {'kind': 'create', 'uri': 'file:///work/sample_app/lib/new.dart'},
          ],
        },
      });

      expect(reply, {'applied': false, 'failureReason': 'Unsupported edit.'});
      expect(appliedEdits, isEmpty);
    });

    // Verifies: IR-001
    test('publishes the diagnostics of each file', () async {
      unawaited(server.listen());
      final published = client.diagnostics.first;

      server.sendNotification('textDocument/publishDiagnostics', {
        'uri': 'file:///work/sample_app/lib/main.dart',
        'diagnostics': [
          {'message': 'Undefined name.', 'severity': 1},
        ],
      });

      final report = await published;
      expect(report.filePath, '/work/sample_app/lib/main.dart');
      expect(report.messages, ['Undefined name.']);
    });

    // Verifies: IR-001
    test('answers a request it has no use for', () async {
      unawaited(server.listen());

      final reply = await server.sendRequest('window/workDoneProgress/create', {
        'token': 'ANALYZING',
      });

      expect(reply, isNull);
    });

    // Verifies: FR-PRP-001
    test('reads the editable arguments at a location', () async {
      server.registerMethod('dart/textDocument/editableArguments', (
        Parameters parameters,
      ) {
        expect(parameters['position']['line'].asInt, 11);
        return {
          'arguments': [
            {
              'name': 'mainAxisAlignment',
              'type': 'enum',
              'value': 'MainAxisAlignment.center',
              'hasArgument': true,
              'options': ['MainAxisAlignment.start'],
              'documentation': 'How to align.',
            },
            {'name': 'spacing', 'type': 'double', 'isEditable': false},
            'not an argument',
          ],
        };
      });
      unawaited(server.listen());

      final arguments = await client.editableArguments((
        filePath: '/work/main.dart',
        position: (line: 11, character: 14),
      ));

      expect(arguments, hasLength(2));
      expect(arguments?.first.kind, EditableArgument.enumKind);
      expect(arguments?.first.value, 'MainAxisAlignment.center');
      expect(arguments?.first.hasArgument, isTrue);
      expect(arguments?.first.isEditable, isTrue);
      expect(arguments?.first.options, ['MainAxisAlignment.start']);
      expect(arguments?.first.documentation, 'How to align.');
      expect(arguments?.last.isEditable, isFalse);
      expect(arguments?.last.hasArgument, isFalse);
    });

    // Verifies: FR-PRP-001
    test('reads no arguments where no widget is created', () async {
      server.registerMethod(
        'dart/textDocument/editableArguments',
        (Parameters _) => null,
      );
      unawaited(server.listen());

      final arguments = await client.editableArguments((
        filePath: '/work/main.dart',
        position: (line: 0, character: 0),
      ));

      expect(arguments, isNull);
    });

    // Verifies: IR-001
    test('reports a refused request as a failure of that method', () async {
      unawaited(server.listen());

      await expectLater(
        client.editArgument(
          (filePath: '/work/main.dart', position: (line: 0, character: 0)),
          documentVersion: 1,
          name: 'spacing',
          newValue: 2,
        ),
        throwsA(
          isA<LspRequestFailed>().having(
            (failure) => failure.method,
            'method',
            'dart/textDocument/editArgument',
          ),
        ),
      );
    });

    // Verifies: FR-INS-002
    test('asks for the Flutter Outline and reads what is published', () async {
      Object? options;
      server.registerMethod('initialize', (Parameters parameters) {
        options = parameters['initializationOptions'].value;
        return <String, Object?>{};
      });
      unawaited(server.listen());
      await client.initialize('/work/sample_app');
      final outline = client.outlines.first;

      server.sendNotification('dart/textDocument/publishFlutterOutline', {
        'uri': 'file:///work/sample_app/lib/main.dart',
        'outline': {
          'kind': 'DART_ELEMENT',
          'range': {
            'start': {'line': 0, 'character': 0},
            'end': {'line': 9, 'character': 0},
          },
          'dartElement': {'name': 'build'},
          'children': [
            {
              'kind': 'NEW_INSTANCE',
              'className': 'Column',
              'range': {
                'start': {'line': 2, 'character': 4},
                'end': {'line': 4, 'character': 5},
              },
            },
            {'kind': 'NEW_INSTANCE', 'className': 'Broken'},
          ],
        },
      });

      final received = await outline;
      expect(options, {'flutterOutline': true});
      expect(received.filePath, '/work/sample_app/lib/main.dart');
      expect(received.root.elementName, 'build');
      expect(received.root.children.single.className, 'Column');
      expect(received.root.children.single.range.start, (
        line: 2,
        character: 4,
      ));
    });
  });
}
