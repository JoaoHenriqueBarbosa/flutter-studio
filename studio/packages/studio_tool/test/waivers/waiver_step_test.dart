import 'dart:io';

import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/source_workspace.dart';

void main() {
  group('WaiverStep', () {
    late Directory sandbox;
    final step = WaiverStep(() => DateTime(2026, 11, 11));
    const registry = '''
| Identificador | Regra | Local | Justificativa | Aprovação | Validade |
| --- | --- | --- | --- | --- | --- |
| WVR-001 | avoid_print | a.dart | Motivo. | Dono, 01/11/2026 | 31/12/2026 |
''';
    const waived = '''
// WVR-@001: the tool writes to the terminal.
// ign@ore: avoid_print
final a = 1;
''';

    setUp(() => sandbox = Directory.systemTemp.createTempSync('waiver_step'));

    tearDown(() => sandbox.deleteSync(recursive: true));

    Future<StepOutcome> run(Map<String, String> sources, {String? waivers}) =>
        step.run(
          createSourceWorkspace(sandbox, sources: sources, waivers: waivers),
        );

    // Verifies: NFR-MNT-008
    test('passes with no suppression and no registry', () async {
      expect(step.id, 'QG-13');
      expect(
        await run({'lib/a.dart': 'final a = 1;\n'}),
        const StepOutcome(StepStatus.passed),
      );
    });

    // Verifies: NFR-MNT-008
    test('passes when a suppression cites a valid waiver', () async {
      final outcome = await run({'lib/a.dart': waived}, waivers: registry);

      expect(outcome.status, StepStatus.passed);
    });

    // Verifies: NFR-MNT-008
    test('fails a suppression with no waiver or an unknown one', () async {
      final outcome = await run({
        'lib/a.dart': '// ign@ore: avoid_print\nfinal a = 1;\n',
        'lib/b.dart': '// WVR-@009: reason.\n// ign@ore: avoid_print\n',
        'lib/c.dart': '// ign@ore_for_file: avoid_print\n',
        'lib/generated.dart':
            '${OwnSources.generatedHeader}\n// ign@ore_for_file: type=lint\n',
      });

      expect(outcome.status, StepStatus.failed);
      expect(outcome.detail, '''
packages/core/lib/a.dart:1 suppresses a diagnostic and cites no waiver.
packages/core/lib/b.dart:2 cites WVR-009, which is not in the registry.
packages/core/lib/c.dart:1 suppresses a whole file that is not generated.''');
    });

    // Verifies: NFR-MNT-008
    test('fails a waiver that is unused or past its validity', () async {
      final unused = await run({
        'lib/a.dart': 'final a = 1;\n',
      }, waivers: registry);
      sandbox.listSync().forEach(
        (entity) => entity.deleteSync(recursive: true),
      );
      final expired = await run({
        'lib/a.dart': waived,
      }, waivers: registry.replaceFirst('31/12/2026', '01/11/2026'));

      expect(unused.detail, 'WVR-001 is in the registry and no code cites it.');
      expect(expired.detail, 'WVR-001 is past its validity.');
    });

    // Verifies: NFR-MNT-005
    test('does not run where there is no workspace', () async {
      expect((await step.run(sandbox)).status, StepStatus.notRun);
    });
  });
}
