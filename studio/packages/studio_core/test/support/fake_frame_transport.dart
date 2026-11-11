import 'dart:typed_data';

import 'package:studio_core/studio_core.dart';

/// A [FrameTransport] that answers with the image that the test sets.
final class FakeFrameTransport implements FrameTransport {
  /// The image of the next capture, or `null` for an app with no frame.
  Uint8List? image;

  /// How many captures were asked for.
  var captureCount = 0;

  /// Whether [close] was called.
  var isClosed = false;

  @override
  Future<Uint8List?> capture() async {
    captureCount++;
    return image;
  }

  @override
  Future<void> close() async => isClosed = true;
}
