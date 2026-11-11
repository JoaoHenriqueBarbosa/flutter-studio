import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/studio_core.dart';

import '../support/fake_frame_transport.dart';

void main() {
  group('CanvasController', () {
    late CanvasController canvas;
    late FakeFrameTransport transport;
    const interval = Duration(milliseconds: 20);

    setUp(() {
      canvas = CanvasController(interval: interval);
      transport = FakeFrameTransport()..image = Uint8List.fromList([1, 2]);
    });

    tearDown(() => canvas.dispose());

    // Verifies: FR-CNV-001
    test('shows the frame of the app as soon as it is attached', () async {
      expect(canvas.frame.value, isNull);
      expect(canvas.isLive.value, isFalse);

      await canvas.attach(transport);

      expect(
        canvas.frame.value,
        Frame(id: 1, pngBytes: Uint8List.fromList([1, 2])),
      );
      expect(canvas.isLive.value, isTrue);
    });

    // Verifies: FR-CNV-001
    test('publishes a frame only when the image changes', () async {
      await canvas.attach(transport);
      await Future<void>.delayed(interval * 4);
      expect(transport.captureCount, greaterThan(1));
      expect(canvas.frame.value?.id, 1);

      transport.image = Uint8List.fromList([3]);
      await canvas.refresh();

      expect(canvas.frame.value?.id, 2);
    });

    // Verifies: FR-CNV-008
    test('keeps the last frame, out of date, when the app ends', () async {
      await canvas.attach(transport);

      await canvas.detach();
      final capturesAtDetach = transport.captureCount;
      await Future<void>.delayed(interval * 3);

      expect(canvas.frame.value?.id, 1);
      expect(canvas.isLive.value, isFalse);
      expect(transport.isClosed, isTrue);
      expect(transport.captureCount, capturesAtDetach);
    });

    // Verifies: FR-CNV-001
    test('keeps the last frame when the app gives none', () async {
      await canvas.attach(transport);
      transport.image = null;

      await canvas.refresh();

      expect(canvas.frame.value?.id, 1);
    });

    // Verifies: FR-CNV-001
    test('replaces the transport of a previous run', () async {
      await canvas.attach(transport);
      final next = FakeFrameTransport()..image = Uint8List.fromList([9]);

      await canvas.attach(next);

      expect(transport.isClosed, isTrue);
      expect(canvas.frame.value?.pngBytes, [9]);
    });
  });
}
