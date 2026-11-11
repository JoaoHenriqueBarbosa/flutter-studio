import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_design_agent/studio_design_agent.dart';

void main() {
  // Verifies: FR-INS-007
  test('DesignAgent speaks the first version of its protocol', () {
    expect(DesignAgent.protocolVersion, 1);
  });

  // Verifies: FR-INS-007
  testWidgets('the framework tells that a test tracks widget creation', (
    tester,
  ) async {
    expect(WidgetInspectorService.instance.isWidgetCreationTracked(), isTrue);
  });
}
