import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/studio_core.dart';
import 'package:studio_shell/studio_shell.dart';

import '../support/workbench_fixture.dart';

void main() {
  // Verifies: FR-INS-002, NFR-INTR-001
  testWidgets('SourceTreePane says so when it has no tree to show', (
    tester,
  ) async {
    final sandbox = Directory.systemTemp.createTempSync('source_tree_pane');
    addTearDown(() => sandbox.deleteSync(recursive: true));
    final session = ProjectSession(
      FlutterProject(
        rootPath: sandbox.path,
        name: 'sample_app',
        sdk: const FlutterSdk(rootPath: '/sdk', version: SdkVersion(3, 47, 9)),
      ),
    );

    await tester.pumpWidget(
      wrapForTest(
        SourceTreePane(
          session: session,
          texts: lookupStudioLocalizations(const Locale('pt')),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Estrutura'), findsOneWidget);
    expect(find.text('Nenhum widget é criado neste arquivo.'), findsOneWidget);
  });
}
