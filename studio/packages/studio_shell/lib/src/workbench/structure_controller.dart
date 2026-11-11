import 'dart:async';

import 'package:devtools_app_shared/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:studio_core/studio_core.dart' show WidgetLocation;
import 'package:studio_protocol/studio_protocol.dart';

import 'workbench_controller.dart';

/// Follows the selection and offers the structural edits that the selected
/// widget accepts (FR-STR-001). Every edit goes through the `Studio`
/// service.
final class StructureController extends DisposableController
    with AutoDisposeControllerMixin {
  /// Creates a controller that reads from [_studio] each time [selection]
  /// changes, and edits through [_edit].
  StructureController(
    this._studio,
    ValueListenable<WidgetLocation?> selection,
    this._edit,
  ) {
    addAutoDisposeListener(selection, _refresh);
    unawaited(_refresh());
  }

  final StudioApi _studio;

  final Future<void> Function(ServiceEdit operation) _edit;

  final _options = ValueNotifier<StructureOptions?>(null);

  /// The widget that [options] was read for.
  WidgetRef? _target;

  /// Number of the last read that started. A read that ends after a newer
  /// one started is dropped.
  var _readCount = 0;

  /// What the selected widget accepts, or `null` when nothing is selected
  /// or the answer is not known.
  ValueListenable<StructureOptions?> get options => _options;

  /// Wraps the selected widget with [wrapper].
  Future<void> wrap(WidgetSpec wrapper) => _run(
    (studio, target) => studio.wrapWidget(target: target, wrapper: wrapper),
  );

  /// Removes the selected widget and keeps its children.
  Future<void> remove() => _run(
    (studio, target) => studio.removeWidget(target: target, keepChildren: true),
  );

  /// Moves the selected widget one place in [direction] among its siblings.
  Future<void> reorder(MoveDirection direction) => _run(
    (studio, target) =>
        studio.reorderWidget(target: target, direction: direction),
  );

  /// Swaps the selected widget with [partner].
  Future<void> swap(SwapPartner partner) => _run(
    (studio, target) => studio.swapWidget(target: target, partner: partner),
  );

  /// Extracts the selected widget, with its subtree, to a new widget class
  /// called [name].
  Future<void> extract(String name) => _run(
    (studio, target) => studio.extractWidget(target: target, name: name),
  );

  @override
  void dispose() {
    // Drops a read that is still on its way.
    _readCount++;
    _options.dispose();
    super.dispose();
  }

  Future<void> _run(
    Future<EditResult> Function(StudioApi studio, WidgetRef target) operation,
  ) async {
    final target = _target;
    if (target == null) return;
    await _edit((studio) => operation(studio, target));
  }

  Future<void> _refresh() async {
    final read = ++_readCount;
    WidgetRef? target;
    StructureOptions? options;
    try {
      target = await _studio.getSelection();
      if (target != null) {
        options = await _studio.getStructureOptions(target: target);
      }
    } on StudioFault {
      // The selection moved on, or the server is restarting. The next
      // change of the selection reads again.
      options = null;
    }
    if (read != _readCount) return;
    _target = target;
    _options.value = options;
  }
}
