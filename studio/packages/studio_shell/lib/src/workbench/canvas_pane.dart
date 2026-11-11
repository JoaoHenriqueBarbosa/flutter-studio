import 'package:devtools_app/devtools_app.dart';
import 'package:devtools_app_shared/ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:studio_core/studio_core.dart' show CanvasController;

import '../l10n/studio_localizations.dart';

/// The canvas: the last frame that the running app drew, as the engine
/// produced it (FR-CNV-001). Nothing of the app is drawn by Studio
/// (FR-CNV-002).
final class CanvasPane extends StatelessWidget {
  /// Creates the pane that shows the frames of [canvas].
  const CanvasPane({super.key, required this.canvas, required this.texts});

  /// Opacity of a frame of an app that ended.
  static const _staleOpacity = 0.4;

  /// Controller that receives the frames.
  final CanvasController canvas;

  /// Text of the interface in the language of the user.
  final StudioLocalizations texts;

  @override
  Widget build(BuildContext context) {
    return MultiValueListenableBuilder(
      listenables: [canvas.frame, canvas.isLive],
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
                  child: Image.memory(
                    frame.pngBytes,
                    // Keeps the previous frame on screen while the next one
                    // is decoded, so the canvas does not blink.
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
