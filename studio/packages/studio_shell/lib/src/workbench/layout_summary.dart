import 'package:devtools_app/devtools_app.dart';
import 'package:devtools_app_shared/ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:studio_core/studio_core.dart'
    show CanvasController, SceneGeometry, SelectionController;
import 'package:studio_protocol/studio_protocol.dart'
    show LayoutInfo, SceneElement;

import '../l10n/studio_localizations.dart';

/// The size, the constraints and the flex data that the selected widget
/// has in the running app (FR-PRP-011).
///
/// It shows nothing while the frame on the canvas has no scene or the
/// selected widget is not on it.
final class LayoutSummary extends StatelessWidget {
  /// Creates the summary of the widget of [selection], read from the frame
  /// of [canvas].
  const LayoutSummary({
    super.key,
    required this.canvas,
    required this.selection,
    required this.texts,
  });

  /// Controller with the frame and its scene.
  final CanvasController canvas;

  /// The selection shared with the other views.
  final SelectionController selection;

  /// Text of the interface in the language of the user.
  final StudioLocalizations texts;

  @override
  Widget build(BuildContext context) {
    return MultiValueListenableBuilder(
      listenables: [canvas.frame, canvas.isLive, selection.selection],
      builder: (context, _, _) {
        final element = _selectedElement();
        if (element == null) return const SizedBox.shrink();
        final layout = element.layout;
        final style = Theme.of(context).subtleTextStyle;
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: denseSpacing,
            vertical: densePadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                texts.layoutSize(
                  _number(element.width),
                  _number(element.height),
                ),
                style: style,
              ),
              if (layout != null) Text(_constraints(layout), style: style),
              if (layout?.flex case final flex?)
                Text(
                  texts.layoutFlex('$flex', layout?.fit?.name ?? ''),
                  style: style,
                ),
            ],
          ),
        );
      },
    );
  }

  /// Returns the first element of the live scene that the selected widget
  /// creates, or `null` when there is none.
  SceneElement? _selectedElement() {
    final scene = canvas.frame.value?.scene;
    final selected = selection.selection.value;
    if (scene == null || selected == null || !canvas.isLive.value) return null;
    return SceneGeometry(scene).elementsCreatedAt((
      filePath: selected.filePath,
      position: selected.position,
    )).firstOrNull;
  }

  String _constraints(LayoutInfo layout) => texts.layoutConstraints(
    _number(layout.minWidth),
    _number(layout.maxWidth),
    _number(layout.minHeight),
    _number(layout.maxHeight),
  );

  /// Returns [value] with one decimal place, or the word for a maximum
  /// that does not exist.
  String _number(double? value) =>
      value == null ? texts.layoutUnbounded : value.toStringAsFixed(1);
}
