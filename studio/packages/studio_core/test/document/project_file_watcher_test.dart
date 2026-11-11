import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:studio_core/studio_core.dart';

void main() {
  group('ProjectFileWatcher', () {
    late Directory project;
    late String filePath;
    late DocumentStore store;
    late ProjectFileWatcher watcher;
    late List<Set<String>> reported;
    const quietPeriod = Duration(milliseconds: 50);

    /// Waits for longer than the events of a write take to be reported.
    Future<void> settle() => Future<void>.delayed(quietPeriod * 8);

    setUp(() async {
      project = Directory.systemTemp.createTempSync('file_watcher_test');
      filePath = path.join(project.path, 'lib', 'main.dart');
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsStringSync('a\n');
      Directory(path.join(project.path, 'build')).createSync();
      Directory(path.join(project.path, '.dart_tool')).createSync();
      store = DocumentStore(project.path);
      watcher = ProjectFileWatcher(
        project.path,
        store,
        quietPeriod: quietPeriod,
      );
      reported = [];
      watcher.externalChanges.listen(reported.add);
      watcher.start();
      await settle();
    });

    tearDown(() async {
      await watcher.dispose();
      await store.dispose();
      project.deleteSync(recursive: true);
    });

    // Verifies: FR-DOC-003
    test('reloads a document that another process saves', () async {
      store.document(filePath);

      File(filePath).writeAsStringSync('b\n');
      await settle();

      expect(reported, [
        {filePath},
      ]);
      expect(store.document(filePath).text, 'b\n');
      expect(store.document(filePath).version, 2);
    });

    // Verifies: FR-DOC-003
    test('reports a Dart file that the store has not read', () async {
      final otherPath = path.join(project.path, 'lib', 'other.dart');

      File(otherPath).writeAsStringSync('c\n');
      await settle();

      expect(reported, [
        {otherPath},
      ]);
    });

    // Verifies: FR-DOC-003
    test('reaches a directory created after the watch started', () async {
      final newPath = path.join(project.path, 'lib', 'pages', 'home.dart');
      Directory(path.dirname(newPath)).createSync();
      await settle();

      File(newPath).writeAsStringSync('d\n');
      await settle();

      expect(reported.last, {newPath});
    });

    // Verifies: FR-DOC-003
    test('does not report what the store itself writes', () async {
      await store.apply(
        WorkspaceEdit([
          (
            filePath: filePath,
            edits: [
              (
                range: (
                  start: (line: 0, character: 0),
                  end: (line: 0, character: 1),
                ),
                newText: 'z',
              ),
            ],
          ),
        ]),
      );
      await settle();

      expect(reported, isEmpty);
      expect(store.canUndo.value, isTrue);
    });

    // Verifies: FR-DOC-003
    test('ignores other files and the directories of tools', () async {
      File(path.join(project.path, 'lib', 'notes.txt')).writeAsStringSync('n');
      File(path.join(project.path, 'build', 'x.dart')).writeAsStringSync('x');
      File(path.join(project.path, '.dart_tool', 'y.dart'))
          .writeAsStringSync('y');
      await settle();

      expect(reported, isEmpty);
    });
  });
}
