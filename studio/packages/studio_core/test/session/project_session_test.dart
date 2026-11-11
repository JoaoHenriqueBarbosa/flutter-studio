import 'dart:io';

import 'package:dtd/dtd.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:path/path.dart' as path;
import 'package:studio_core/studio_core.dart';
import 'package:studio_protocol/studio_protocol.dart';

import '../support/sample_app.dart';

/// Waits until the analysis server has registered [method] in the daemon.
Future<void> _waitForLspMethod(DartToolingDaemon tool, String method) async {
  while (true) {
    final services = await tool.getRegisteredServices();
    final registered = services.clientServices.any(
      (service) => service.name == 'Lsp' && service.methods.containsKey(method),
    );
    if (registered) return;
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}

void main() {
  group('ProjectSession', () {
    late Directory sandbox;
    late ProjectSession session;
    late String mainPath;

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('project_session_test');
      final projectPath = createSampleApp(sandbox);
      mainPath = path.join(projectPath, 'lib', 'main.dart');
      final project = ProjectLoader(
        SdkLocator(environment: Platform.environment),
      ).load(projectPath);
      session = ProjectSession(project);
    });

    tearDown(() async {
      await session.close();
      sandbox.deleteSync(recursive: true);
    });

    // Verifies: FR-PRJ-004, FR-PRP-003, FR-DOC-001, FR-DOC-007
    test(
      'writes to disk the argument edit that a tool asks the server for',
      () async {
        await session.start();
        final daemonUri = session.daemonUri.value;
        if (daemonUri == null) fail('The daemon did not start.');
        final tool = await DartToolingDaemon.connect(daemonUri);
        addTearDown(tool.close);
        const editArgument = 'dart/textDocument/editArgument';
        await _waitForLspMethod(tool, editArgument);

        await tool.call(
          'Lsp',
          editArgument,
          params: {
            'textDocument': {'uri': '${Uri.file(mainPath)}'},
            'position': {'line': 11, 'character': 16},
            'edit': {
              'name': 'mainAxisAlignment',
              'newValue': 'MainAxisAlignment.end',
            },
          },
        );

        expect(
          File(mainPath).readAsStringSync(),
          sampleAppSource.replaceFirst(
            'MainAxisAlignment.center',
            'MainAxisAlignment.end',
          ),
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    // Verifies: FR-API-001, FR-PRP-001, FR-PRP-003, FR-DOC-005, FR-DOC-006,
    // NFR-REL-004, NFR-SEC-002, IR-003
    test(
      'a client of the daemon reads, edits and undoes through Studio',
      () async {
        await session.start();
        final daemonUri = session.daemonUri.value;
        if (daemonUri == null) fail('The daemon did not start.');
        final tool = await DartToolingDaemon.connect(daemonUri);
        addTearDown(tool.close);
        await tool.streamListen(StudioContract.streamName);
        final events = <String>[];
        final subscription = tool
            .onEvent(StudioContract.streamName)
            .listen((event) => events.add(event.kind));
        addTearDown(subscription.cancel);
        final studio = StudioClient((method, params) async {
          final response = await tool.call(
            StudioContract.serviceName,
            method.name,
            params: params,
          );
          return response.result[StudioContract.resultKey];
        });
        final column = WidgetRef(
          uri: '${Uri.file(mainPath)}',
          position: const Position(line: 11, character: 14),
          documentVersion: 1,
        );

        expect((await studio.getVersion()).version, StudioContract.version);
        expect(await studio.select(target: column), column);
        final properties = await studio.getProperties(target: column);
        final alignment = properties.firstWhere(
          (property) => property.name == 'mainAxisAlignment',
        );
        expect(alignment.type, 'enum');
        expect(alignment.expression?.source, 'MainAxisAlignment.center');
        expect(alignment.options, contains('MainAxisAlignment.end'));

        final result = await studio.setProperty(
          target: column,
          name: 'mainAxisAlignment',
          value: const Expression(source: 'MainAxisAlignment.end'),
        );

        expect(result.applied, isTrue);
        expect(result.documentVersions, {column.uri: 2});
        expect(result.reload, ReloadKind.none);
        expect(
          File(mainPath).readAsStringSync(),
          sampleAppSource.replaceFirst(
            'MainAxisAlignment.center',
            'MainAxisAlignment.end',
          ),
        );
        expect((await studio.getSelection())?.documentVersion, 2);
        await expectLater(
          studio.getProperties(target: column),
          throwsA(
            isA<RpcException>()
                .having((exception) => exception.code, 'code', -32001)
                .having((exception) => exception.data, 'data', 2),
          ),
        );

        expect((await studio.undo()).applied, isTrue);

        expect(File(mainPath).readAsStringSync(), sampleAppSource);
        expect(events, containsAll(['selectionChanged', 'documentChanged']));
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    // Verifies: FR-STR-001, FR-DOC-006, NFR-REL-004
    test('wraps a widget with an assist of the server and undoes it', () async {
      await session.start();
      final column = WidgetRef(
        uri: '${Uri.file(mainPath)}',
        position: const Position(line: 11, character: 14),
        documentVersion: 1,
      );
      const center = WidgetSpec(
        libraryUri: 'package:flutter/widgets.dart',
        className: 'Center',
      );

      final options = await session.service.getStructureOptions(target: column);
      expect(options.wrappers, contains(center));
      expect(options.canMoveUp, isFalse);

      final result = await session.service.wrapWidget(
        target: column,
        wrapper: center,
      );

      expect(result.applied, isTrue);
      expect(
        File(mainPath).readAsStringSync(),
        contains('body: Center(\n          child: Column('),
      );

      await session.service.undo();

      expect(File(mainPath).readAsStringSync(), sampleAppSource);
    }, timeout: const Timeout(Duration(minutes: 2)));

    // Verifies: FR-INS-002, IR-004
    test('derives the tree of widgets from the source of a file', () async {
      await session.start();

      final roots = await session.service.getSourceTree(
        uri: '${Uri.file(mainPath)}',
      );

      expect(roots.first.className, 'SampleApp');
      expect(roots.first.owner, 'main');
      final app = roots.last;
      expect(app.className, 'MaterialApp');
      expect(app.owner, 'SampleApp.build');
      expect(app.ref.position, const Position(line: 9, character: 17));
      final column = app.children.single.children.single;
      expect(column.className, 'Column');
      // The same location that the framework records at run time.
      expect(column.ref.position, const Position(line: 11, character: 14));
      expect(column.children.single.className, 'Text');
      expect(
        await session.service.getProperties(target: column.ref),
        isNotEmpty,
      );
    }, timeout: const Timeout(Duration(minutes: 2)));

    // Verifies: FR-CNV-001, FR-CNV-008, FR-HST-002, FR-RUN-001, FR-DOC-002
    test('runs the app on the design host and shows its frames', () async {
      await session.start();
      const pngSignature = [0x89, 0x50, 0x4E, 0x47];
      Future<Frame> nextFrame({required int after}) async {
        while ((session.canvas.frame.value?.id ?? 0) <= after) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        return session.canvas.frame.value ?? (throw StateError('No frame.'));
      }

      await session.startApp(target: const RunTarget.designHost());
      final first = await nextFrame(after: 0);

      expect(first.pngBytes.take(pngSignature.length), pngSignature);
      expect(session.canvas.isLive.value, isTrue);

      final result = await session.service.setProperty(
        target: WidgetRef(
          uri: '${Uri.file(mainPath)}',
          position: const Position(line: 11, character: 14),
          documentVersion: 1,
        ),
        name: 'mainAxisAlignment',
        value: const Expression(source: 'MainAxisAlignment.end'),
      );
      final second = await nextFrame(after: first.id);

      expect(result.reload, ReloadKind.hotReload);
      expect(second.pngBytes, isNot(first.pngBytes));

      await session.stopApp();

      expect(session.canvas.isLive.value, isFalse);
      expect(session.canvas.frame.value, isNotNull);
    }, timeout: const Timeout(Duration(minutes: 3)));

    // Verifies: FR-DOC-003, FR-API-004
    test('follows a file that another program saves', () async {
      await session.start();
      final daemonUri = session.daemonUri.value;
      if (daemonUri == null) fail('The daemon did not start.');
      final tool = await DartToolingDaemon.connect(daemonUri);
      addTearDown(tool.close);
      await tool.streamListen(StudioContract.streamName);
      final externalChange = tool
          .onEvent(StudioContract.streamName)
          .where((event) => event.kind == StudioEvent.documentChanged.name)
          .map((event) => DocumentChanged.fromJson(event.data))
          .firstWhere((change) => change.origin == ChangeOrigin.external);
      final column = WidgetRef(
        uri: '${Uri.file(mainPath)}',
        position: const Position(line: 11, character: 14),
        documentVersion: 1,
      );
      await session.service.select(target: column);

      File(mainPath)
          .writeAsStringSync(sampleAppSource.replaceFirst('.center', '.start'));

      expect((await externalChange).documentVersion, 2);
      final properties = await session.service.getProperties(
        target: WidgetRef(
          uri: column.uri,
          position: column.position,
          documentVersion: 2,
        ),
      );
      expect(
        properties
            .firstWhere((property) => property.name == 'mainAxisAlignment')
            .expression
            ?.source,
        'MainAxisAlignment.start',
      );
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
