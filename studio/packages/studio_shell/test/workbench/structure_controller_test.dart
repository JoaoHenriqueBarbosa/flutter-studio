import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/studio_core.dart' show WidgetLocation;
import 'package:studio_protocol/studio_protocol.dart';
import 'package:studio_shell/studio_shell.dart';

/// A [StudioApi] with a selection and options that the test sets, which
/// records the structural edits it is asked for.
final class _StructureApi implements StudioApi {
  WidgetRef? selection;

  StructureOptions? options;

  final edits = <String>[];

  @override
  Future<WidgetRef?> getSelection() async => selection;

  @override
  Future<StructureOptions> getStructureOptions({
    required WidgetRef target,
  }) async =>
      options ?? (throw const StudioFault(StudioErrorCode.staleDocument));

  @override
  Future<EditResult> wrapWidget({
    required WidgetRef target,
    required WidgetSpec wrapper,
  }) => _record('wrap ${wrapper.className} at ${target.documentVersion}');

  @override
  Future<EditResult> removeWidget({
    required WidgetRef target,
    required bool keepChildren,
  }) => _record('remove, keepChildren $keepChildren');

  @override
  Future<EditResult> reorderWidget({
    required WidgetRef target,
    required MoveDirection direction,
  }) => _record('reorder ${direction.name}');

  @override
  Future<EditResult> swapWidget({
    required WidgetRef target,
    required SwapPartner partner,
  }) => _record('swap ${partner.name}');

  @override
  Future<EditResult> extractWidget({
    required WidgetRef target,
    required String name,
  }) => _record('extract $name');

  Future<EditResult> _record(String edit) async {
    edits.add(edit);
    return const EditResult(
      applied: true,
      changes: [],
      documentVersions: {},
      reload: ReloadKind.none,
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('StructureController', () {
    late _StructureApi studio;
    late ValueNotifier<WidgetLocation?> selection;
    late StructureController controller;
    const center = WidgetSpec(
      libraryUri: 'package:flutter/widgets.dart',
      className: 'Center',
    );
    const options = StructureOptions(
      wrappers: [center],
      canRemove: true,
      canMoveUp: false,
      canMoveDown: true,
      canSwapWithParent: false,
      canSwapWithChild: false,
    );

    void select({required int documentVersion}) {
      studio.selection = WidgetRef(
        uri: 'file:///work/lib/main.dart',
        position: const Position(line: 11, character: 14),
        documentVersion: documentVersion,
      );
      selection.value = (
        filePath: '/work/lib/main.dart',
        position: (line: 11, character: 14),
        documentVersion: documentVersion,
      );
    }

    setUp(() {
      studio = _StructureApi();
      selection = ValueNotifier(null);
      controller = StructureController(
        studio,
        selection,
        (operation) => operation(studio),
      );
    });

    tearDown(() {
      controller.dispose();
      selection.dispose();
    });

    // Verifies: FR-STR-001
    test('offers nothing while nothing is selected', () async {
      await pumpEventQueue();

      expect(controller.options.value, isNull);
      await controller.remove();
      expect(studio.edits, isEmpty);
    });

    // Verifies: FR-STR-001, FR-INS-003
    test('reads the options of the widget that gets selected', () async {
      studio.options = options;

      select(documentVersion: 1);
      await pumpEventQueue();

      expect(controller.options.value, options);
    });

    // Verifies: FR-STR-001
    test('offers nothing when the options cannot be read', () async {
      select(documentVersion: 1);
      await pumpEventQueue();

      expect(controller.options.value, isNull);
    });

    // Verifies: FR-STR-001, FR-STR-007, FR-API-002
    test('sends each edit to the service, for the selected widget', () async {
      studio.options = options;
      select(documentVersion: 1);
      await pumpEventQueue();
      select(documentVersion: 2);
      await pumpEventQueue();

      await controller.wrap(center);
      await controller.remove();
      await controller.reorder(MoveDirection.down);
      await controller.swap(SwapPartner.parent);
      await controller.extract('Body');

      expect(studio.edits, [
        'wrap Center at 2',
        'remove, keepChildren true',
        'reorder down',
        'swap parent',
        'extract Body',
      ]);
    });
  });
}
