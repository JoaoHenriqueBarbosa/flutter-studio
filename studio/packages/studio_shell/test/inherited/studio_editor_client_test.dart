import 'dart:convert';
import 'dart:io';

import 'package:devtools_app/devtools_app.dart';
import 'package:devtools_app_shared/service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_protocol/studio_protocol.dart';
import 'package:studio_shell/studio_shell.dart';

/// A [StudioApi] that records each `setProperty` and answers as the test
/// sets.
final class _RecordingApi implements StudioApi {
  final edits = <(WidgetRef, String, Expression?)>[];

  StudioFault? fault;

  @override
  Future<EditResult> setProperty({
    required WidgetRef target,
    required String name,
    required Expression? value,
  }) async {
    edits.add((target, name, value));
    final fault = this.fault;
    if (fault != null) throw fault;
    return const EditResult(
      applied: true,
      changes: [],
      documentVersions: {},
      reload: ReloadKind.none,
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('StudioEditorClient', () {
    late Process daemon;
    late DTDManager daemonManager;
    late _RecordingApi studio;
    late StudioEditorClient client;
    final document = TextDocument(
      uriAsString: 'file:///work/lib/main.dart',
      version: 3,
    );
    final cursor = CursorPosition(line: 11, character: 14);

    setUp(() async {
      daemon = await Process.start('dart', ['tooling-daemon', '--machine']);
      final handshake = await daemon.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first;
      final Object? details = jsonDecode(handshake);
      if (details case {'tooling_daemon_details': {'uri': final String uri}}) {
        daemonManager = DTDManager();
        await daemonManager.connect(Uri.parse(uri));
      } else {
        fail('Unexpected handshake: $handshake');
      }
      studio = _RecordingApi();
      client = StudioEditorClient(daemonManager, studio);
      await client.initialized;
    });

    tearDown(() async {
      client.dispose();
      await daemonManager.disconnect();
      daemon.kill();
    });

    Future<GenericApiResponse> edit(Object? value, {TextDocument? of}) =>
        client.editArgument(
          textDocument: of ?? document,
          position: cursor,
          name: 'label',
          value: value,
          screenId: 'test',
        );

    // Verifies: FR-API-002
    test('sends an edit to the Studio service, as an expression', () async {
      final response = await edit('MainAxisAlignment.end');

      expect(response.success, isTrue);
      expect(studio.edits.single, (
        const WidgetRef(
          uri: 'file:///work/lib/main.dart',
          position: Position(line: 11, character: 14),
          documentVersion: 3,
        ),
        'label',
        const Expression(source: 'MainAxisAlignment.end'),
      ));
    });

    // Verifies: FR-API-002
    test('writes the other values as their source', () async {
      await edit(42);
      await edit(null);

      expect(
        [for (final (_, _, value) in studio.edits) value?.source],
        ['42', 'null'],
      );
    });

    // Verifies: FR-API-002, NFR-INTR-005
    test('reports the fault of the service to the panel', () async {
      studio.fault = const StudioFault(StudioErrorCode.staleDocument, data: 4);

      final response = await edit(1);

      expect(response.success, isFalse);
      expect(response.errorMessage, 'StaleDocument: 4');
      expect(response.errorCode, -32001);
    });

    // Verifies: FR-API-002
    test('refuses to edit a document announced without a version', () async {
      final response = await edit(
        1,
        of: TextDocument(uriAsString: document.uriAsString, version: null),
      );

      expect(response.success, isFalse);
      expect(studio.edits, isEmpty);
    });

    // Verifies: FR-API-002
    test('offers no operation that edits around the service', () async {
      final refactors = await client.getRefactors(
        textDocument: document,
        range: EditorRange(start: cursor, end: cursor),
        screenId: 'test',
      );
      final response = await client.executeCommand(
        commandName: 'refactor.perform',
        commandArgs: const [],
        screenId: 'test',
      );

      expect(refactors, isNull);
      expect(response.success, isFalse);
    });

    // Verifies: FR-PRP-001
    test('reads no arguments while the server offers none', () async {
      final result = await client.getEditableArguments(
        textDocument: document,
        position: cursor,
        screenId: 'test',
      );

      expect(result, isNull);
    });
  });
}
