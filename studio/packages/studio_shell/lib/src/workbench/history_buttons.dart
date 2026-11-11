import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/studio_localizations.dart';
import 'workbench_controller.dart';

/// The buttons that undo and redo the edits of the open project
/// (FR-DOC-005).
final class HistoryButtons extends StatelessWidget {
  /// Creates the buttons, each one enabled while its listenable is true.
  const HistoryButtons({
    super.key,
    required this.controller,
    required this.canUndo,
    required this.canRedo,
    required this.texts,
  });

  /// Controller that undoes and redoes.
  final WorkbenchController controller;

  /// Whether there is an edit to undo.
  final ValueListenable<bool> canUndo;

  /// Whether there is an undone edit to redo.
  final ValueListenable<bool> canRedo;

  /// Text of the interface in the language of the user.
  final StudioLocalizations texts;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder(
          valueListenable: canUndo,
          builder: (context, isEnabled, _) => DevToolsButton(
            icon: Icons.undo,
            label: texts.undoAction,
            onPressed: isEnabled ? controller.undo : null,
          ),
        ),
        const SizedBox(width: denseSpacing),
        ValueListenableBuilder(
          valueListenable: canRedo,
          builder: (context, isEnabled, _) => DevToolsButton(
            icon: Icons.redo,
            label: texts.redoAction,
            onPressed: isEnabled ? controller.redo : null,
          ),
        ),
      ],
    );
  }
}
