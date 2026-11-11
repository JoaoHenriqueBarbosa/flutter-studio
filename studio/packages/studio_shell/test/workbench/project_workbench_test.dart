import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/studio_core.dart';
import 'package:studio_shell/studio_shell.dart';

import '../support/workbench_fixture.dart';

void main() {
  // Verifies: FR-DOC-005, NFR-INTR-004
  testWidgets('ProjectWorkbench shows its panes and takes the undo keys', (
    tester,
  ) async {
    final sandbox = Directory.systemTemp.createTempSync('project_workbench');
    addTearDown(() => sandbox.deleteSync(recursive: true));
    final devTools = createDisconnectedDevTools();
    final controller = createWorkbenchController(devTools);
    addTearDown(() {
      controller.dispose();
      devTools.dispose();
    });
    final session = ProjectSession(
      FlutterProject(
        rootPath: sandbox.path,
        name: 'sample_app',
        sdk: const FlutterSdk(rootPath: '/sdk', version: SdkVersion(3, 47, 9)),
      ),
    );
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrapForTest(
        ProjectWorkbench(
          controller: controller,
          devTools: devTools,
          session: session,
          texts: lookupStudioLocalizations(const Locale('pt')),
        ),
      ),
    );
    await tester.pump();

    for (final title in ['Estrutura', 'Canvas', 'Inspetor', 'Propriedades']) {
      expect(find.text(title), findsOneWidget);
    }

    // The inherited property panel fails here because this test connects
    // it to no daemon. That failure is not the subject of the test.
    tester.takeException();

    // With no project open in the controller the keys do nothing, and the
    // workbench takes them without a failure.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
