import 'dart:io';

import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

void main() {
  // Verifies: NFR-MNT-008
  test('WaiverRegistry reads each waiver with its validity', () {
    final sandbox = Directory.systemTemp.createTempSync('waiver_registry');
    addTearDown(() => sandbox.deleteSync(recursive: true));
    final file = File('${sandbox.path}/waivers.md')
      ..writeAsStringSync('''
| WVR-001 | regra | local | motivo | Dono, 01/11/2026 | 31/12/2026 |
| WVR-002 | regra | local | motivo | Dono, 01/11/2026 | Até a issue fechar |
''');

    final registry = WaiverRegistry.read(file);

    expect(registry.validUntil, {
      'WVR-001': DateTime(2026, 12, 31),
      'WVR-002': null,
    });
    expect(registry.isExpired('WVR-001', DateTime(2027)), isTrue);
    expect(registry.isExpired('WVR-002', DateTime(2027)), isFalse);
    expect(registry.contains('WVR-003'), isFalse);
    expect(
      WaiverRegistry.read(File('${sandbox.path}/none.md')).validUntil,
      isEmpty,
    );
  });
}
