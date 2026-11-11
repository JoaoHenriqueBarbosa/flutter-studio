import 'package:flutter/foundation.dart';
import 'package:studio_protocol/studio_protocol.dart' show AgentInfo, Scene;

/// What a transport captures: the image, encoded as PNG, and the scene
/// mirror of the same moment, which is `null` when the app runs without
/// the design agent.
typedef CapturedFrame = ({Uint8List pngBytes, Scene? scene});

/// Brings to the shell the frames that the app of the project draws.
///
/// A Strategy: the frames arrive in a different way from each kind of
/// design host (ADR-0009).
abstract interface class FrameTransport {
  /// Completes with what the app shows now, or with `null` when the app
  /// gives no image, because it ended or has drawn nothing yet.
  Future<CapturedFrame?> capture();

  /// Completes with what the design agent of the app tells about itself,
  /// or with `null` when the app runs without the agent.
  Future<AgentInfo?> readAgentInfo();

  /// Releases the connection with the app.
  Future<void> close();
}
