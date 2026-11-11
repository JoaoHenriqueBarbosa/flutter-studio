import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/studio_core.dart'
    show DocumentChange, TextDocument, WidgetLocation;
import 'package:studio_protocol/studio_protocol.dart';
import 'package:studio_shell/studio_shell.dart';

/// A [StudioApi] with one widget for each file, which records what it is
/// asked to read and to select.
final class _TreeApi implements StudioApi {
  final readUris = <String>[];

  final selected = <WidgetRef>[];

  var isFailing = false;

  @override
  Future<List<SourceNode>> getSourceTree({required String uri}) async {
    readUris.add(uri);
    if (isFailing) throw const StudioFault(StudioErrorCode.unsupportedTarget);
    return [nodeOf(uri)];
  }

  @override
  Future<WidgetRef> select({required WidgetRef target}) async {
    selected.add(target);
    if (isFailing) throw const StudioFault(StudioErrorCode.staleDocument);
    return target;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The widget that the fake creates in the file [uri].
SourceNode nodeOf(String uri) => SourceNode(
  ref: WidgetRef(
    uri: uri,
    position: const Position(line: 3, character: 4),
    documentVersion: 1,
  ),
  className: 'Column',
  children: const [],
);

void main() {
  group('SourceTreeController', () {
    late _TreeApi studio;
    late ValueNotifier<WidgetLocation?> selection;
    late StreamController<DocumentChange> changes;
    late SourceTreeController controller;
    const mainPath = '/work/lib/main.dart';
    const pagePath = '/work/lib/page.dart';
    const mainUri = 'file:///work/lib/main.dart';
    const pageUri = 'file:///work/lib/page.dart';

    setUp(() {
      studio = _TreeApi();
      selection = ValueNotifier(null);
      changes = StreamController.broadcast();
      controller = SourceTreeController(
        studio,
        selection,
        changes.stream,
        initialFilePath: mainPath,
      );
    });

    tearDown(() async {
      controller.dispose();
      selection.dispose();
      await changes.close();
    });

    // Verifies: FR-INS-002
    test('shows the tree of the entry point at first', () async {
      await pumpEventQueue();

      expect(studio.readUris, [mainUri]);
      expect(controller.roots.value, [nodeOf(mainUri)]);
    });

    // Verifies: FR-INS-003
    test('moves to the file of the selection and marks the widget', () async {
      selection.value = (
        filePath: pagePath,
        position: (line: 3, character: 4),
        documentVersion: 1,
      );
      await pumpEventQueue();

      expect(studio.readUris.last, pageUri);
      expect(controller.isSelected(nodeOf(pageUri)), isTrue);
      expect(controller.isSelected(nodeOf(mainUri)), isFalse);
    });

    // Verifies: FR-INS-002, FR-DOC-003
    test('reads the tree again when its document changes', () async {
      await pumpEventQueue();
      const document = TextDocument('', version: 2);

      changes
        ..add((
          filePath: pagePath,
          document: document,
          origin: ChangeOrigin.studio,
        ))
        ..add((
          filePath: mainPath,
          document: document,
          origin: ChangeOrigin.external,
        ));
      await pumpEventQueue();

      expect(studio.readUris, [mainUri, mainUri]);
    });

    // Verifies: FR-INS-003, FR-API-001
    test('selects through the service', () async {
      await controller.select(nodeOf(mainUri));

      expect(studio.selected, [nodeOf(mainUri).ref]);
    });

    // Verifies: FR-INS-002
    test('shows nothing when the tree cannot be read', () async {
      await pumpEventQueue();
      studio.isFailing = true;

      changes.add((
        filePath: mainPath,
        document: const TextDocument('', version: 2),
        origin: ChangeOrigin.studio,
      ));
      await pumpEventQueue();
      await controller.select(nodeOf(mainUri));

      expect(controller.roots.value, isEmpty);
    });
  });
}
