import 'dart:typed_data';

import 'package:studio_core/studio_core.dart';
import 'package:studio_protocol/studio_protocol.dart' show Scene;

/// A [FrameTransport] that answers with the image that the test sets.
final class FakeFrameTransport implements FrameTransport {
  /// The image of the next capture, or `null` for an app with no frame.
  Uint8List? image;

  /// How many captures were asked for.
  var captureCount = 0;

  /// Whether [close] was called.
  var isClosed = false;

  /// The scene of the next capture.
  Scene? scene;

  @override
  Future<CapturedFrame?> capture() async {
    captureCount++;
    final image = this.image;
    return image == null ? null : (pngBytes: image, scene: scene);
  }

  @override
  Future<void> close() async => isClosed = true;
}
