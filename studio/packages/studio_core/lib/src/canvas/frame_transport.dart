import 'package:flutter/foundation.dart';

/// Brings to the shell the frames that the app of the project draws.
///
/// A Strategy: the frames arrive in a different way from each kind of
/// design host (ADR-0009).
abstract interface class FrameTransport {
  /// Completes with the image that the app shows now, encoded as PNG, or
  /// with `null` when the app gives none, because it ended or has drawn
  /// nothing yet.
  Future<Uint8List?> capture();

  /// Releases the connection with the app.
  Future<void> close();
}
