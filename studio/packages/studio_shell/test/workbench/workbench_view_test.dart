import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:studio_shell/studio_shell.dart';

import '../support/workbench_fixture.dart';

void main() {
  group('WorkbenchView', () {
    late InheritedDevTools devTools;
    late WorkbenchController controller;

    setUp(() {
      devTools = createDisconnectedDevTools();
      controller = createWorkbenchController(devTools);
    });

    tearDown(() {
      controller.dispose();
      devTools.dispose();
    });

    Future<void> pumpView(WidgetTester tester, Locale locale) =>
        tester.pumpWidget(
          wrapForTest(
            WorkbenchView(
              controller: controller,
              devTools: devTools,
              texts: lookupStudioLocalizations(locale),
            ),
          ),
        );

    // Verifies: FR-PRJ-001, NFR-INTR-001
    testWidgets('invites to open a project, in the language of the user', (
      tester,
    ) async {
      await pumpView(tester, const Locale('pt'));

      expect(
        find.text('Escolha o diretório de um projeto Flutter para começar.'),
        findsOneWidget,
      );
      expect(find.text('Abrir projeto'), findsOneWidget);
    });

    // Verifies: FR-PRJ-001
    testWidgets('explains why a directory was not opened', (tester) async {
      final sandbox = Directory.systemTemp.createTempSync('workbench_view');
      addTearDown(() => sandbox.deleteSync(recursive: true));
      await pumpView(tester, const Locale('en'));

      await tester.runAsync(() => controller.openProject(sandbox.path));
      await tester.pump();

      expect(
        find.text('${sandbox.path} is not a Flutter project.'),
        findsOneWidget,
      );
      expect(find.text('Open project'), findsOneWidget);
    });
  });
}
