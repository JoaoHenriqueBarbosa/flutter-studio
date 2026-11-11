import 'dart:io';

import 'package:devtools_app/devtools_app.dart';
import 'package:devtools_app_shared/ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:studio_core/studio_core.dart';
import 'package:studio_protocol/studio_protocol.dart' show SceneElement;

import '../l10n/studio_localizations.dart';

/// The canvas: the last frame that the running app drew, as the engine
/// produced it (FR-CNV-001), with the outline of the selected widget over
/// it. Nothing of the app is drawn by Studio (FR-CNV-002).
///
/// A click selects the widget of the project under the pointer, when the
/// frame comes with a scene (FR-INS-003).
final class CanvasPane extends StatelessWidget {
  /// Creates the pane that shows the frames of [canvas] and follows
  /// [selection].
  const CanvasPane({
    super.key,
    required this.canvas,
    required this.selection,
    required this.texts,
  });

  /// Opacity of a frame of an app that ended.
  static const _staleOpacity = 0.4;

  /// Controller that receives the frames.
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
        final frame = canvas.frame.value;
        if (frame == null) return Center(child: Text(texts.canvasPlaceholder));
        final isLive = canvas.isLive.value;
        return Padding(
          padding: const EdgeInsets.all(denseSpacing),
          child: Column(
            children: [
              if (!isLive)
                Padding(
                  padding: const EdgeInsets.only(bottom: denseSpacing),
                  child: Text(texts.canvasStale),
                ),
              Expanded(
                child: Opacity(
                  opacity: isLive ? 1 : _staleOpacity,
                  child: _surface(frame),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _surface(Frame frame) {
    final image = Image.memory(
      frame.pngBytes,
      // Keeps the previous frame on screen while the next one is decoded,
      // so the canvas does not blink.
      gaplessPlayback: true,
    );
    final scene = frame.scene;
    if (scene == null) return image;
    final geometry = SceneGeometry(scene);
    final selected = selection.selection.value;
    return Center(
      child: AspectRatio(
        aspectRatio: scene.width / scene.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = constraints.maxWidth / scene.width;
            return GestureDetector(
              // The whole surface takes the click, whatever the image does.
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _select(
                geometry.locationAt(
                  details.localPosition.dx / scale,
                  details.localPosition.dy / scale,
                ),
              ),
              child: CustomPaint(
                foregroundPainter: _SelectionPainter(
                  selected == null
                      ? const []
                      : geometry.elementsCreatedAt((
                          filePath: selected.filePath,
                          position: selected.position,
                        )),
                  scale: scale,
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: image,
              ),
            );
          },
        ),
      ),
    );
  }

  void _select(SourceLocation? location) {
    if (location == null) return;
    try {
      selection.select(location);
    } on EditFailure {
      // The widget is created outside the project.
    } on FileSystemException {
      // The file was removed after the frame was drawn.
    }
  }
}

/// Paints the outline of the selected elements over the frame.
final class _SelectionPainter extends CustomPainter {
  const _SelectionPainter(
    this._elements, {
    required this.scale,
    required this.color,
  });

  static const _strokeWidth = 2.0;

  final List<SceneElement> _elements;

  /// Pixels of the canvas for each logical pixel of the surface.
  final double scale;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    for (final element in _elements) {
      canvas.drawRect(
        Rect.fromLTWH(
          element.left * scale,
          element.top * scale,
          element.width * scale,
          element.height * scale,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SelectionPainter oldDelegate) =>
      oldDelegate._elements != _elements ||
      oldDelegate.scale != scale ||
      oldDelegate.color != color;
}
