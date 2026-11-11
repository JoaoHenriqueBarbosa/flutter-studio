import 'package:flutter/foundation.dart';

/// One image of what the app of the project draws (FR-CNV-001).
@immutable
final class Frame {
  /// Creates the frame number [id], whose image is [pngBytes].
  const Frame({required this.id, required this.pngBytes});

  /// Number of the frame, which grows at each new image of a canvas.
  final int id;

  /// The image, encoded as PNG.
  final Uint8List pngBytes;

  @override
  bool operator ==(Object other) =>
      other is Frame && other.id == id && listEquals(other.pngBytes, pngBytes);

  @override
  int get hashCode => Object.hash(id, pngBytes.length);

  @override
  String toString() => 'Frame($id, ${pngBytes.length} bytes)';
}
