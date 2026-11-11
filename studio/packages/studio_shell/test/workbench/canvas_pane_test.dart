import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/widgets.dart' show Image;
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/studio_core.dart';
import 'package:studio_protocol/studio_protocol.dart'
    show AgentInfo, Position, Scene, SceneElement;
import 'package:studio_shell/studio_shell.dart';

import '../support/workbench_fixture.dart';

/// A [FrameTransport] that always answers with the same image and scene.
final class _OneFrameTransport implements FrameTransport {
  const _OneFrameTransport(
    this._image, {
    this.scene,
    this.isWidgetCreationTracked = true,
  });

  final Uint8List _image;

  final Scene? scene;

  final bool isWidgetCreationTracked;

  @override
  Future<AgentInfo?> readAgentInfo() async => scene == null
      ? null
      : AgentInfo(
          protocolVersion: 1,
          isWidgetCreationTracked: isWidgetCreationTracked,
        );

  @override
  Future<CapturedFrame?> capture() async => (pngBytes: _image, scene: scene);

  @override
  Future<void> close() async {}
}

/// A PNG image of one pixel.
final _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  group('CanvasPane', () {
    late Directory project;
    late String filePath;
    late DocumentStore documents;
    late SelectionController selection;
    late CanvasController canvas;

    setUp(() {
      project = Directory.systemTemp.createTempSync('canvas_pane_test');
      filePath = '${project.path}/main.dart';
      File(filePath).writeAsStringSync('Column()\n');
      documents = DocumentStore(project.path);
      selection = SelectionController(documents);
      canvas = CanvasController(interval: const Duration(hours: 1));
    });

    tearDown(() => project.deleteSync(recursive: true));

    Future<void> pumpPane(WidgetTester tester) => tester.pumpWidget(
      wrapForTest(
        CanvasPane(
          canvas: canvas,
          selection: selection,
          texts: lookupStudioLocalizations(const Locale('pt')),
        ),
      ),
    );

    // Verifies: FR-CNV-001, NFR-INTR-001
    testWidgets('invites to run the app before the first frame', (
      tester,
    ) async {
      await pumpPane(tester);

      expect(find.text('Execute o app para vê-lo aqui.'), findsOneWidget);
      await tester.runAsync(canvas.dispose);
    });

    // Verifies: FR-CNV-001, FR-CNV-008
    testWidgets('shows the frame, and marks it when the app ends', (
      tester,
    ) async {
      await pumpPane(tester);

      await tester.runAsync(
        () => canvas.attach(_OneFrameTransport(_onePixelPng)),
      );
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(find.textContaining('último quadro'), findsNothing);

      await tester.runAsync(canvas.detach);
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(find.textContaining('último quadro'), findsOneWidget);
      await tester.runAsync(canvas.dispose);
    });

    // Verifies: FR-INS-003, FR-CNV-006
    testWidgets('a click selects the widget of the project under it', (
      tester,
    ) async {
      final scene = Scene(
        width: 100,
        height: 100,
        devicePixelRatio: 1,
        elements: [
          SceneElement(
            className: 'Column',
            uri: '${Uri.file(filePath)}',
            position: const Position(line: 0, character: 0),
            parentIndex: -1,
            left: 0,
            top: 0,
            width: 100,
            height: 50,
          ),
        ],
      );
      await pumpPane(tester);
      await tester.runAsync(
        () => canvas.attach(_OneFrameTransport(_onePixelPng, scene: scene)),
      );
      await tester.pump();
      final surface = tester.getRect(find.byType(Image));

      // The lower half of the surface has no element of the project.
      await tester.tapAt(surface.center + Offset(0, surface.height / 4));
      expect(selection.selection.value, isNull);

      await tester.tapAt(surface.center - Offset(0, surface.height / 4));
      expect(selection.selection.value, (
        filePath: filePath,
        position: (line: 0, character: 0),
        documentVersion: 1,
      ));
      await tester.runAsync(canvas.dispose);
    });

    // Verifies: FR-INS-007
    testWidgets('says so and selects nothing in an app without tracking', (
      tester,
    ) async {
      const scene = Scene(
        width: 100,
        height: 100,
        devicePixelRatio: 1,
        elements: [],
      );
      await pumpPane(tester);
      await tester.runAsync(
        () => canvas.attach(
          _OneFrameTransport(
            _onePixelPng,
            scene: scene,
            isWidgetCreationTracked: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('sem o rastreamento'), findsOneWidget);
      await tester.tapAt(tester.getCenter(find.byType(Image)));
      expect(selection.selection.value, isNull);
      await tester.runAsync(canvas.dispose);
    });
  });
}
