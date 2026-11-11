import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:studio_core/studio_core.dart';

void main() {
  group('SelectionController', () {
    late Directory project;
    late String filePath;
    late DocumentStore store;
    late SelectionController controller;

    setUp(() {
      project = Directory.systemTemp.createTempSync('selection_test');
      filePath = path.join(project.path, 'main.dart');
      File(filePath).writeAsStringSync('Column()\n');
      store = DocumentStore(project.path);
      controller = SelectionController(store);
    });

    tearDown(() async {
      await controller.dispose();
      await store.dispose();
      project.deleteSync(recursive: true);
    });

    // Verifies: FR-INS-003
    test('selects a location in the current version of its document', () {
      final selected = controller.select((
        filePath: filePath,
        position: (line: 0, character: 0),
      ));

      expect(selected, (
        filePath: filePath,
        position: (line: 0, character: 0),
        documentVersion: 1,
      ));
      expect(controller.selection.value, selected);

      controller.clear();
      expect(controller.selection.value, isNull);
    });

    // Verifies: FR-INS-006
    test('moves the selection to the new version of its document', () async {
      controller.select((
        filePath: filePath,
        position: (line: 0, character: 0),
      ));

      await store.apply(
        WorkspaceEdit([
          (
            filePath: filePath,
            edits: [
              (
                range: (
                  start: (line: 0, character: 7),
                  end: (line: 0, character: 7),
                ),
                newText: 'spacing: 2',
              ),
            ],
          ),
        ]),
      );
      await pumpEventQueue();

      expect(controller.selection.value?.documentVersion, 2);
    });

    // Verifies: NFR-SEC-003
    test('refuses a file outside the project', () {
      expect(
        () => controller.select((
          filePath: '/etc/hosts',
          position: (line: 0, character: 0),
        )),
        throwsA(isA<EditOutsideProject>()),
      );
      expect(controller.selection.value, isNull);
    });
  });
}
