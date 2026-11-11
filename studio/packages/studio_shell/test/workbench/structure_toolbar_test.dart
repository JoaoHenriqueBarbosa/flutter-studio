import 'dart:io';
import 'dart:ui';

import 'package:devtools_app_shared/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/studio_core.dart';
import 'package:studio_shell/studio_shell.dart';

import '../support/workbench_fixture.dart';

void main() {
  group('StructureToolbar', () {
    late Directory sandbox;
    late InheritedDevTools devTools;
    late WorkbenchController controller;
    late ProjectSession session;

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('structure_toolbar');
      devTools = createDisconnectedDevTools();
      controller = createWorkbenchController(devTools);
      session = ProjectSession(
        FlutterProject(
          rootPath: sandbox.path,
          name: 'sample_app',
          sdk: const FlutterSdk(
            rootPath: '/sdk',
            version: SdkVersion(3, 47, 9),
          ),
        ),
      );
    });

    tearDown(() {
      controller.dispose();
      devTools.dispose();
      sandbox.deleteSync(recursive: true);
    });

    // Verifies: FR-STR-001, NFR-INTR-001
    testWidgets('offers no edit while nothing is selected', (tester) async {
      await tester.pumpWidget(
        wrapForTest(
          StructureToolbar(
            session: session,
            controller: controller,
            texts: lookupStudioLocalizations(const Locale('pt')),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Envolver com'), findsOneWidget);
      final actions = tester.widgetList<DevToolsButton>(
        find.byType(DevToolsButton),
      );
      expect(actions, hasLength(5));
      expect(actions.every((action) => action.onPressed == null), isTrue);
    });
  });
}
