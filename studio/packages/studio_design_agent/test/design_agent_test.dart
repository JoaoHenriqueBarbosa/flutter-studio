import 'package:flutter_test/flutter_test.dart';
import 'package:studio_design_agent/studio_design_agent.dart';

void main() {
  // Verifies: FR-HST-003
  test('DesignAgent speaks the first version of its protocol', () {
    expect(DesignAgent.protocolVersion, 1);
  });
}
