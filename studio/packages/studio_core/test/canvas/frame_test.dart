import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/studio_core.dart';

void main() {
  // Verifies: FR-CNV-001
  test('Frame is equal to a frame with the same number and image', () {
    final frame = Frame(id: 1, pngBytes: Uint8List.fromList([1, 2]));

    expect(frame, Frame(id: 1, pngBytes: Uint8List.fromList([1, 2])));
    expect(frame, isNot(Frame(id: 2, pngBytes: Uint8List.fromList([1, 2]))));
    expect(frame, isNot(Frame(id: 1, pngBytes: Uint8List.fromList([1, 3]))));
  });
}
