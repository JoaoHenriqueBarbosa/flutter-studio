import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_shell/studio_shell.dart';

import '../support/workbench_fixture.dart';

void main() {
  // Verifies: FR-RUN-003
  testWidgets('OutputPane follows the output as it grows', (tester) async {
    final output = ValueNotifier('Launching lib/main.dart\n');
    addTearDown(output.dispose);
    await tester.pumpWidget(
      wrapForTest(OutputPane(title: 'Output', output: output)),
    );

    expect(find.text('Launching lib/main.dart\n'), findsOneWidget);

    output.value += 'Reloaded 1 of 754 libraries\n';
    await tester.pump();

    expect(
      find.text('Launching lib/main.dart\nReloaded 1 of 754 libraries\n'),
      findsOneWidget,
    );
  });
}
