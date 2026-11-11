import 'dart:ui';

import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_shell/studio_shell.dart';

import '../support/workbench_fixture.dart';

void main() {
  group('HistoryButtons', () {
    late InheritedDevTools devTools;
    late WorkbenchController controller;
    late ValueNotifier<bool> canUndo;
    late ValueNotifier<bool> canRedo;

    setUp(() {
      devTools = createDisconnectedDevTools();
      controller = createWorkbenchController(devTools);
      canUndo = ValueNotifier(false);
      canRedo = ValueNotifier(false);
    });

    tearDown(() {
      canUndo.dispose();
      canRedo.dispose();
      controller.dispose();
      devTools.dispose();
    });

    bool isEnabled(WidgetTester tester, String label) =>
        tester
            .widget<DevToolsButton>(
              find.ancestor(
                of: find.text(label),
                matching: find.byType(DevToolsButton),
              ),
            )
            .onPressed !=
        null;

    // Verifies: FR-DOC-005, NFR-INTR-001
    testWidgets('enables each button while there is something to do', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapForTest(
          HistoryButtons(
            controller: controller,
            canUndo: canUndo,
            canRedo: canRedo,
            texts: lookupStudioLocalizations(const Locale('pt')),
          ),
        ),
      );

      expect(isEnabled(tester, 'Desfazer'), isFalse);
      expect(isEnabled(tester, 'Refazer'), isFalse);

      canUndo.value = true;
      await tester.pump();

      expect(isEnabled(tester, 'Desfazer'), isTrue);
      expect(isEnabled(tester, 'Refazer'), isFalse);
    });
  });
}
