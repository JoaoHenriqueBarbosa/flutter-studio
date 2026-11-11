@Tags(['desktop'])
library;

import 'dart:io';

import 'package:dtd/dtd.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:studio_core/studio_core.dart';

import '../support/sample_app.dart';

void main() {
  // Verifies: FR-RUN-001, FR-RUN-003, FR-DOC-002, FR-PRP-003
  test('ProjectSession reloads the running app after an edit', () async {
    final sandbox = Directory.systemTemp.createTempSync('app_run_test');
    addTearDown(() => sandbox.deleteSync(recursive: true));
    final projectPath = createSampleApp(sandbox);
    final mainPath = path.join(projectPath, 'lib', 'main.dart');
    final session = ProjectSession(
      ProjectLoader(SdkLocator(environment: Platform.environment))
          .load(projectPath),
    );
    addTearDown(session.close);
    await session.start();

    final run = await session.startApp(target: RunTarget.desktop());
    final output = StringBuffer();
    final reloaded = run.output
        .map((text) => (output..write(text)).toString())
        .firstWhere((text) => text.contains('Reloaded'));
    await run.vmServiceUri;

    final daemonUri = session.daemonUri.value;
    if (daemonUri == null) fail('The daemon did not start.');
    final tool = await DartToolingDaemon.connect(daemonUri);
    addTearDown(tool.close);
    await tool.call(
      'Lsp',
      'dart/textDocument/editArgument',
      params: {
        'textDocument': {'uri': '${Uri.file(mainPath)}'},
        'position': {'line': 11, 'character': 16},
        'edit': {
          'name': 'mainAxisAlignment',
          'newValue': 'MainAxisAlignment.end',
        },
      },
    );

    expect(await reloaded, contains('Reloaded'));
    expect(
      File(mainPath).readAsStringSync(),
      contains('mainAxisAlignment: MainAxisAlignment.end'),
    );

    await session.stopApp();
    expect(session.appRun.value, isNull);
  });
}
