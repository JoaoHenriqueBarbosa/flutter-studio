import 'dart:io';

import 'package:dtd/dtd.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:studio_core/studio_core.dart';

import '../support/sample_app.dart';

/// Waits until the analysis server has registered [method] in the daemon.
Future<void> _waitForLspMethod(DartToolingDaemon tool, String method) async {
  while (true) {
    final services = await tool.getRegisteredServices();
    final registered = services.clientServices.any(
      (service) => service.name == 'Lsp' && service.methods.containsKey(method),
    );
    if (registered) return;
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}

void main() {
  group('ProjectSession', () {
    late Directory sandbox;
    late ProjectSession session;
    late String mainPath;

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('project_session_test');
      final projectPath = createSampleApp(sandbox);
      mainPath = path.join(projectPath, 'lib', 'main.dart');
      final project = ProjectLoader(
        SdkLocator(environment: Platform.environment),
      ).load(projectPath);
      session = ProjectSession(project);
    });

    tearDown(() async {
      await session.close();
      sandbox.deleteSync(recursive: true);
    });

    // Verifies: FR-PRJ-004, FR-PRP-003, FR-DOC-001, FR-DOC-007
    test(
      'writes to disk the argument edit that a tool asks the server for',
      () async {
        await session.start();
        final daemonUri = session.daemonUri.value;
        if (daemonUri == null) fail('The daemon did not start.');
        final tool = await DartToolingDaemon.connect(daemonUri);
        addTearDown(tool.close);
        const editArgument = 'dart/textDocument/editArgument';
        await _waitForLspMethod(tool, editArgument);

        await tool.call(
          'Lsp',
          editArgument,
          params: {
            'textDocument': {'uri': '${Uri.file(mainPath)}'},
            'position': {'line': 11, 'character': 16},
            'edit': {
              'name': 'mainAxisAlignment',
              'newValue': 'MainAxisAlignment.end',
            },
          },
        );

        expect(
          File(mainPath).readAsStringSync(),
          sampleAppSource.replaceFirst(
            'MainAxisAlignment.center',
            'MainAxisAlignment.end',
          ),
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
