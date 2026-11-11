import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:studio_core/studio_core.dart';

void main() {
  group('DocumentStore', () {
    late Directory project;
    late String filePath;
    late DocumentStore store;

    setUp(() {
      project = Directory.systemTemp.createTempSync('document_store_test');
      filePath = path.join(project.path, 'lib', 'main.dart');
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsStringSync('alignment: .center,\n');
      store = DocumentStore(project.path);
    });

    tearDown(() async {
      await store.dispose();
      project.deleteSync(recursive: true);
    });

    WorkspaceEdit replaceCenter(String filePath) => WorkspaceEdit([
      (
        filePath: filePath,
        edits: [
          (
            range: (
              start: (line: 0, character: 11),
              end: (line: 0, character: 18),
            ),
            newText: '.end',
          ),
        ],
      ),
    ]);

    // Verifies: FR-DOC-001, FR-DOC-007
    test('writes the edited text to disk and advances the version', () async {
      await store.apply(replaceCenter(filePath));

      expect(File(filePath).readAsStringSync(), 'alignment: .end,\n');
      expect(store.document(filePath).version, 2);
    });

    // Verifies: FR-DOC-001
    test('announces each file after it reaches the disk', () async {
      final changed = expectLater(store.changedFiles, emits(filePath));

      await store.apply(replaceCenter(filePath));

      await changed;
    });

    // Verifies: NFR-REL-003
    test('leaves no temporary file behind', () async {
      await store.apply(replaceCenter(filePath));

      expect(
        [
          for (final entity in File(filePath).parent.listSync())
            path.basename(entity.path),
        ],
        ['main.dart'],
      );
    });

    // Verifies: NFR-REL-003
    test('changes no file when one edit of the set is invalid', () async {
      final otherPath = path.join(project.path, 'lib', 'other.dart');
      File(otherPath).writeAsStringSync('x\n');
      final edit = WorkspaceEdit([
        ...replaceCenter(filePath).fileEdits,
        (
          filePath: otherPath,
          edits: [
            (
              range: (
                start: (line: 9, character: 0),
                end: (line: 9, character: 1),
              ),
              newText: 'y',
            ),
          ],
        ),
      ]);

      await expectLater(store.apply(edit), throwsRangeError);

      expect(File(filePath).readAsStringSync(), 'alignment: .center,\n');
      expect(File(otherPath).readAsStringSync(), 'x\n');
    });

    // Verifies: IR-005
    test('refuses to edit a file outside the project', () async {
      final outside = Directory.systemTemp.createTempSync('outside_project');
      addTearDown(() => outside.deleteSync(recursive: true));
      final outsidePath = path.join(outside.path, 'main.dart');
      File(outsidePath).writeAsStringSync('alignment: .center,\n');

      await expectLater(
        store.apply(replaceCenter(outsidePath)),
        throwsA(isA<EditOutsideProject>()),
      );

      expect(File(outsidePath).readAsStringSync(), 'alignment: .center,\n');
    });
  });
}
