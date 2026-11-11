import 'dart:convert';
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

/// Returns the global settings of the Flutter tool of this user, or `null`
/// when the tool has written none.
String? _readFlutterSettings() {
  final home = Platform.environment['HOME'] ?? '';
  final configHome =
      Platform.environment['XDG_CONFIG_HOME'] ?? path.join(home, '.config');
  for (final settingsPath in [
    path.join(configHome, 'flutter', 'settings'),
    path.join(home, '.flutter_settings'),
  ]) {
    final file = File(settingsPath);
    if (file.existsSync()) return file.readAsStringSync();
  }
  return null;
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

    // Verifies: FR-PRP-007, FR-PRP-008, FR-DOC-006
    test('edits the text of an argument through the service', () async {
      await session.start();
      final uri = '${Uri.file(mainPath)}';
      WidgetRef column(int documentVersion) => WidgetRef(
        uri: uri,
        position: const Position(line: 11, character: 14),
        documentVersion: documentVersion,
      );

      await session.service.setProperty(
        target: column(1),
        name: 'mainAxisAlignment',
        value: const Expression(source: 'MainAxisAlignment.values.first'),
      );

      expect(
        File(mainPath).readAsStringSync(),
        sampleAppSource.replaceFirst(
          'MainAxisAlignment.center',
          'MainAxisAlignment.values.first',
        ),
      );

      final removed = await session.service.setProperty(
        target: column(2),
        name: 'mainAxisAlignment',
        value: null,
      );

      expect(removed.applied, isTrue);
      expect(
        File(mainPath).readAsStringSync(),
        sampleAppSource.replaceFirst(
          '          mainAxisAlignment: MainAxisAlignment.center,\n',
          '',
        ),
      );
      final properties = await session.service.getProperties(target: column(3));
      expect(
        properties
            .firstWhere((property) => property.name == 'mainAxisAlignment')
            .isSet,
        isFalse,
      );

      await session.service.undo();
      await session.service.undo();

      expect(File(mainPath).readAsStringSync(), sampleAppSource);
    }, timeout: const Timeout(Duration(minutes: 2)));

    // Verifies: FR-STR-007, FR-DOC-006
    test('extracts a widget and converts a class to stateful', () async {
      await session.start();
      final uri = '${Uri.file(mainPath)}';

      final extracted = await session.service.extractWidget(
        target: WidgetRef(
          uri: uri,
          position: const Position(line: 11, character: 14),
          documentVersion: 1,
        ),
        name: 'Body',
      );

      expect(extracted.applied, isTrue);
      final afterExtract = File(mainPath).readAsStringSync();
      expect(afterExtract, contains('body: Body()'));
      expect(afterExtract, contains('class Body extends StatelessWidget {'));

      final converted = await session.service.convertToStatefulWidget(
        declaration: WidgetRef(
          uri: uri,
          position: const Position(line: 4, character: 8),
          documentVersion: 2,
        ),
      );

      expect(converted.applied, isTrue);
      expect(
        File(mainPath).readAsStringSync(),
        allOf(
          contains('class SampleApp extends StatefulWidget {'),
          contains('class _SampleAppState extends State<SampleApp> {'),
        ),
      );

      await session.service.undo();
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

    // Verifies: FR-CNV-001, FR-CNV-006, FR-CNV-008, FR-HST-001, FR-HST-002,
    // FR-RUN-001, FR-DOC-002, FR-INS-001, IR-004, NFR-COMP-002
    test('runs the app on the design host and shows its frames', () async {
      await session.close();
      session = ProjectSession(
        session.project,
        studioPackagesPath: Directory.current.parent.path,
      );
      await session.start();
      const pngSignature = [0x89, 0x50, 0x4E, 0x47];
      final flutterSettings = _readFlutterSettings();
      Future<Frame> nextFrame({required int after}) async {
        while ((session.canvas.frame.value?.id ?? 0) <= after ||
            session.canvas.frame.value?.scene == null) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        return session.canvas.frame.value ?? (throw StateError('No frame.'));
      }

      await session.startApp(target: const RunTarget.designHost());
      final first = await nextFrame(after: 0);

      expect(first.pngBytes.take(pngSignature.length), pngSignature);
      expect(session.canvas.isLive.value, isTrue);
      // The scene has the widgets of the project, and only them, at the
      // locations where the source tree has them.
      final scene = first.scene ?? (throw StateError('No scene.'));
      expect(
        scene.elements.every((it) => it.uri == '${Uri.file(mainPath)}'),
        isTrue,
      );
      expect(scene.elements.map((it) => it.position), [
        const Position(line: 2, character: 28),
        const Position(line: 9, character: 17),
        const Position(line: 10, character: 12),
        const Position(line: 11, character: 14),
        const Position(line: 13, character: 21),
      ]);
      expect((scene.width, scene.height), (800, 600));
      expect(session.canvas.isSelectable, isTrue);
      final runtimeTree = await session.service.getRuntimeTree();
      expect(runtimeTree.single.className, 'SampleApp');
      expect(
        runtimeTree.single.children.single.children.single.children.single.ref,
        WidgetRef(
          uri: '${Uri.file(mainPath)}',
          position: const Position(line: 11, character: 14),
          documentVersion: 1,
        ),
      );
      // Running the app leaves the settings of the SDK of the user as they
      // were (NFR-COMP-002).
      expect(_readFlutterSettings(), flutterSettings);
      expect(
        File(path.join(session.project.rootPath, 'pubspec.yaml'))
            .readAsStringSync(),
        isNot(contains('studio_design')),
      );

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

    // Verifies: FR-HST-001
    test('the design host finds the assets of the project', () async {
      final rootPath = session.project.rootPath;
      File(path.join(rootPath, 'assets', 'dot.png'))
        ..createSync(recursive: true)
        ..writeAsBytesSync(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhf'
            'DwAChwGA60e6kgAAAABJRU5ErkJggg==',
          ),
        );
      final manifest = File(path.join(rootPath, 'pubspec.yaml'));
      manifest.writeAsStringSync(
        manifest.readAsStringSync().replaceFirst(
          '  uses-material-design: true',
          '  uses-material-design: true\n  assets:\n    - assets/dot.png',
        ),
      );
      File(mainPath).writeAsStringSync('''
import 'package:flutter/widgets.dart';

void main() => runApp(
  Directionality(
    textDirection: TextDirection.ltr,
    child: Column(
      children: [
        Image.asset('assets/dot.png', width: 40, height: 40),
        Image.asset('assets/missing.png', width: 40, height: 40),
      ],
    ),
  ),
);
''');
      await session.close();
      session = ProjectSession(
        session.project,
        studioPackagesPath: Directory.current.parent.path,
      );
      await session.start();

      final run = await session.startApp(target: const RunTarget.designHost());
      final output = StringBuffer();
      final subscription = run.output.listen(output.write);
      addTearDown(subscription.cancel);
      while (session.canvas.frame.value?.scene?.elements.length != 4) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      // Time for the image to be loaded, or to fail, after the first frame.
      await Future<void>.delayed(const Duration(seconds: 2));

      // The image that the project does not have fails as in any app, which
      // shows that a failure would be seen here.
      expect('$output', contains('Unable to load asset: "assets/missing.png"'));
      expect('$output', isNot(contains('"assets/dot.png"')));
    }, timeout: const Timeout(Duration(minutes: 3)));

    // Verifies: FR-CNV-001, NFR-REL-001
    test(
      'keeps reloading while the canvas captures frames without pause',
      () async {
        await session.close();
        session = ProjectSession(
          session.project,
          canvas: CanvasController(interval: const Duration(milliseconds: 5)),
        );
        await session.start();
        await session.startApp(target: const RunTarget.designHost());
        while (session.canvas.frame.value == null) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        const editCount = 8;
        var version = 1;

        for (var edit = 0; edit < editCount; edit++) {
          final reloaded = session.appRun.value?.output.firstWhere(
            (text) => text.contains('Reloaded'),
          );
          await session.service.setProperty(
            target: WidgetRef(
              uri: '${Uri.file(mainPath)}',
              position: const Position(line: 11, character: 14),
              documentVersion: version++,
            ),
            name: 'mainAxisAlignment',
            value: Expression(
              source: edit.isEven
                  ? 'MainAxisAlignment.end'
                  : 'MainAxisAlignment.center',
            ),
          );
          await reloaded;
        }

        expect(session.canvas.isLive.value, isTrue);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

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
