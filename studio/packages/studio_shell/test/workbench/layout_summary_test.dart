import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/studio_core.dart';
import 'package:studio_protocol/studio_protocol.dart';
import 'package:studio_shell/studio_shell.dart';

import '../support/workbench_fixture.dart';

/// A [FrameTransport] that always answers with the same image and scene.
final class _SceneTransport implements FrameTransport {
  const _SceneTransport(this._scene);

  final Scene _scene;

  @override
  Future<CapturedFrame?> capture() async => (
    pngBytes: Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAC'
        'hwGA60e6kgAAAABJRU5ErkJggg==',
      ),
    ),
    scene: _scene,
  );

  @override
  Future<AgentInfo?> readAgentInfo() async =>
      const AgentInfo(protocolVersion: 1, isWidgetCreationTracked: true);

  @override
  Future<void> close() async {}
}

void main() {
  // Verifies: FR-PRP-011, NFR-INTR-001
  testWidgets('LayoutSummary shows the layout of the selected widget', (
    tester,
  ) async {
    final project = Directory.systemTemp.createTempSync('layout_summary');
    addTearDown(() => project.deleteSync(recursive: true));
    final filePath = '${project.path}/main.dart';
    File(filePath).writeAsStringSync('Expanded()\n');
    final selection = SelectionController(DocumentStore(project.path));
    final canvas = CanvasController(interval: const Duration(hours: 1));
    final scene = Scene(
      width: 800,
      height: 600,
      devicePixelRatio: 3,
      elements: [
        SceneElement(
          className: 'Expanded',
          uri: '${Uri.file(filePath)}',
          position: const Position(line: 0, character: 0),
          parentIndex: -1,
          left: 0,
          top: 0,
          width: 289.6,
          height: 344,
          layout: const LayoutInfo(
            minWidth: 0,
            maxWidth: 800,
            minHeight: 344,
            flex: 2,
            fit: FlexFitKind.tight,
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      wrapForTest(
        LayoutSummary(
          canvas: canvas,
          selection: selection,
          texts: lookupStudioLocalizations(const Locale('pt')),
        ),
      ),
    );
    await tester.runAsync(() => canvas.attach(_SceneTransport(scene)));
    await tester.pump();

    expect(find.textContaining('Tamanho'), findsNothing);

    selection.select((filePath: filePath, position: (line: 0, character: 0)));
    await tester.pump();

    expect(find.text('Tamanho 289.6 × 344.0'), findsOneWidget);
    expect(
      find.text(
        'Restrições: largura de 0.0 a 800.0, altura de 344.0 a sem limite',
      ),
      findsOneWidget,
    );
    expect(find.text('Flex 2, ajuste tight'), findsOneWidget);
    await tester.runAsync(canvas.dispose);
  });
}
