import 'package:studio_protocol/studio_protocol.dart';
import 'package:test/test.dart';

void main() {
  // Verifies: FR-API-001
  test('StudioFault names the error of the contract and its data', () {
    const fault = StudioFault(StudioErrorCode.staleDocument, data: 4);

    expect(fault.code.code, -32001);
    expect('$fault', 'StaleDocument: 4');
  });
}
