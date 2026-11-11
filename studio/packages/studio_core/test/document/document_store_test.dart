import 'dart:io';
import 'dart:math' as math;

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
      final changed = expectLater(
        store.changes,
        emits(
          isA<DocumentChange>()
              .having((change) => change.filePath, 'filePath', filePath)
              .having((change) => change.document.version, 'version', 2)
              .having((change) => change.origin, 'origin', ChangeOrigin.studio),
        ),
      );

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

      await expectLater(store.apply(edit), throwsA(isA<InvalidEdit>()));

      expect(File(filePath).readAsStringSync(), 'alignment: .center,\n');
      expect(File(otherPath).readAsStringSync(), 'x\n');
    });

    // Verifies: FR-DOC-005, FR-DOC-006
    test(
      'undo restores the exact text and redo applies the edit again',
      () async {
        await store.apply(replaceCenter(filePath));

        final undone = await store.undo();

        expect(File(filePath).readAsStringSync(), 'alignment: .center,\n');
        expect(undone?.versions, {filePath: 3});
        expect(undone?.changes.single.edits.single, (
          range: (
            start: (line: 0, character: 12),
            end: (line: 0, character: 15),
          ),
          newText: 'center',
        ));
        expect(store.canUndo.value, isFalse);
        expect(store.canRedo.value, isTrue);

        await store.redo();

        expect(File(filePath).readAsStringSync(), 'alignment: .end,\n');
        expect(store.canUndo.value, isTrue);
        expect(store.canRedo.value, isFalse);
      },
    );

    // Verifies: FR-DOC-005
    test('undo with no edit changes nothing', () async {
      expect(await store.undo(), isNull);
      expect(await store.redo(), isNull);
    });

    // Verifies: FR-DOC-005
    test('a new edit discards the edits that were undone', () async {
      await store.apply(replaceCenter(filePath));
      await store.undo();

      await store.apply(replaceCenter(filePath));

      expect(store.canRedo.value, isFalse);
    });

    // Verifies: NFR-REL-004
    test(
      'undoing every edit of a random sequence restores the files',
      () async {
        final random = math.Random(20261111);
        const editCount = 100;
        for (var index = 0; index < editCount; index++) {
          final text = store.document(filePath).text;
          final start = random.nextInt(text.length);
          final end = start + random.nextInt(text.length - start);
          await store.apply(
            WorkspaceEdit([
              (
                filePath: filePath,
                edits: [
                  (
                    range: (
                      start: (line: 0, character: start),
                      end: (line: 0, character: end),
                    ),
                    newText: 'x' * random.nextInt(4),
                  ),
                ],
              ),
            ]),
          );
        }

        while (store.canUndo.value) {
          await store.undo();
        }

        expect(File(filePath).readAsStringSync(), 'alignment: .center,\n');
      },
    );

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
