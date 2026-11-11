import 'package:flutter_test/flutter_test.dart';

import '../support/workbench_fixture.dart';

void main() {
  // Verifies: FR-INS-003
  test('InheritedDevTools has no inspector and no selection while '
      'no app is connected', () {
    final devTools = createDisconnectedDevTools();
    addTearDown(devTools.dispose);

    expect(devTools.appConnection.value.connected, isFalse);
    expect(devTools.inspector.value, isNull);
    expect(devTools.selectedLocation.value, isNull);
  });
}
