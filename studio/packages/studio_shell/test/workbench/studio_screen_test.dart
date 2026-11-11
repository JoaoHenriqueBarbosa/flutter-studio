import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:studio_shell/studio_shell.dart';

import '../support/workbench_fixture.dart';

void main() {
  // Verifies: FR-PRJ-001
  testWidgets('StudioScreen is available without a connected app and '
      'shows the body it was given', (tester) async {
    final screen = StudioScreen((context) => const Text('Workbench'));

    await tester.pumpWidget(
      wrapForTest(Builder(builder: screen.buildScreenBody)),
    );

    expect(screen.requiresConnection, isFalse);
    expect(screen.screenId, 'studio');
    expect(find.text('Workbench'), findsOneWidget);
  });
}
