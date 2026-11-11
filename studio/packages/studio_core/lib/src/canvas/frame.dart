import 'package:flutter/foundation.dart';
import 'package:studio_protocol/studio_protocol.dart' show Scene;

/// One image of what the app of the project draws (FR-CNV-001).
@immutable
final class Frame {
  /// Creates the frame number [id], whose image is [pngBytes] and whose
  /// scene mirror is [scene].
  const Frame({required this.id, required this.pngBytes, this.scene});

  /// Number of the frame, which grows at each new image of a canvas.
  final int id;

  /// The image, encoded as PNG.
  final Uint8List pngBytes;

  /// The geometry and the creation location of each element of the project
  /// in the image, or `null` when the app runs without the design agent.
  final Scene? scene;

  @override
  bool operator ==(Object other) =>
      other is Frame &&
      other.id == id &&
      other.scene == scene &&
      listEquals(other.pngBytes, pngBytes);

  @override
  int get hashCode => Object.hash(id, pngBytes.length);

  @override
  String toString() => 'Frame($id, ${pngBytes.length} bytes)';
}
