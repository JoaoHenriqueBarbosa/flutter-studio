import 'dart:io';

import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/trace_workspace.dart';

void main() {
  // Verifies: NFR-MNT-005
  test('WorkspaceTrace reads the increment under construction', () {
    final sandbox = Directory.systemTemp.createTempSync('workspace_trace');
    addTearDown(() => sandbox.deleteSync(recursive: true));
    final workspace = createTraceWorkspace(
      sandbox,
      testSource: '',
      currentIncrement: 'F0',
    );

    expect(const WorkspaceTrace().read(workspace).currentIncrement, 'F0');
    expect(
      () => const WorkspaceTrace().read(sandbox),
      throwsA(isA<FileSystemException>()),
    );
  });
}
