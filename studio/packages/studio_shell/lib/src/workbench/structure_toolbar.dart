import 'package:devtools_app_shared/ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:studio_core/studio_core.dart';
import 'package:studio_protocol/studio_protocol.dart';

import '../l10n/studio_localizations.dart';
import 'structure_controller.dart';
import 'workbench_controller.dart';

/// The bar with the structural edits of the selected widget: wrap, remove,
/// move among the siblings and swap with a neighbor (FR-STR-001).
final class StructureToolbar extends StatefulWidget {
  /// Creates the toolbar for the selection of [session].
  const StructureToolbar({
    super.key,
    required this.session,
    required this.controller,
    required this.texts,
  });

  /// The session of the open project.
  final ProjectSession session;

  /// Controller through which the edits reach the service.
  final WorkbenchController controller;

  /// Text of the interface in the language of the user.
  final StudioLocalizations texts;

  @override
  State<StructureToolbar> createState() => _StructureToolbarState();
}

final class _StructureToolbarState extends State<StructureToolbar> {
  late StructureController _structure;

  @override
  void initState() {
    super.initState();
    _structure = _createController();
  }

  @override
  void didUpdateWidget(StructureToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      _structure.dispose();
      _structure = _createController();
    }
  }

  @override
  void dispose() {
    _structure.dispose();
    super.dispose();
  }

  StructureController _createController() => StructureController(
    widget.session.service,
    widget.session.selection.selection,
    widget.controller.edit,
  );

  @override
  Widget build(BuildContext context) {
    final texts = widget.texts;
    return ValueListenableBuilder(
      valueListenable: _structure.options,
      builder: (context, options, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: denseSpacing),
        child: Row(
          children: [
            _WrapMenu(
              label: texts.wrapWithAction,
              wrappers: options?.wrappers ?? const [],
              onSelected: _structure.wrap,
            ),
            const Spacer(),
            DevToolsButton(
              outlined: false,
              icon: Icons.arrow_upward,
              tooltip: texts.moveUpAction,
              onPressed: options?.canMoveUp ?? false
                  ? () => _structure.reorder(MoveDirection.up)
                  : null,
            ),
            DevToolsButton(
              outlined: false,
              icon: Icons.arrow_downward,
              tooltip: texts.moveDownAction,
              onPressed: options?.canMoveDown ?? false
                  ? () => _structure.reorder(MoveDirection.down)
                  : null,
            ),
            DevToolsButton(
              outlined: false,
              icon: Icons.move_up,
              tooltip: texts.swapWithParentAction,
              onPressed: options?.canSwapWithParent ?? false
                  ? () => _structure.swap(SwapPartner.parent)
                  : null,
            ),
            DevToolsButton(
              outlined: false,
              icon: Icons.move_down,
              tooltip: texts.swapWithChildAction,
              onPressed: options?.canSwapWithChild ?? false
                  ? () => _structure.swap(SwapPartner.child)
                  : null,
            ),
            DevToolsButton(
              outlined: false,
              icon: Icons.delete_outline,
              tooltip: texts.removeWidgetAction,
              onPressed: options?.canRemove ?? false ? _structure.remove : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// The menu that lists the widgets the selection can be wrapped with.
final class _WrapMenu extends StatelessWidget {
  const _WrapMenu({
    required this.label,
    required this.wrappers,
    required this.onSelected,
  });

  final String label;

  final List<WidgetSpec> wrappers;

  final ValueChanged<WidgetSpec> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = wrappers.isNotEmpty;
    return PopupMenuButton<WidgetSpec>(
      enabled: isEnabled,
      tooltip: label,
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final wrapper in wrappers)
          PopupMenuItem(
            value: wrapper,
            height: defaultButtonHeight,
            child: Text(wrapper.className),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: densePadding),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: isEnabled ? theme.regularTextStyle : theme.subtleTextStyle,
            ),
            Icon(
              Icons.arrow_drop_down,
              size: defaultIconSize,
              color: isEnabled ? null : theme.disabledColor,
            ),
          ],
        ),
      ),
    );
  }
}
