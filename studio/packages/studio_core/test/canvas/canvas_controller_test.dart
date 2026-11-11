import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/studio_core.dart';
import 'package:studio_protocol/studio_protocol.dart' show AgentInfo, Scene;

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

    // Verifies: FR-CNV-001, NFR-REL-001
    test('captures nothing while an action holds the canvas back', () async {
      await canvas.attach(transport);
      final capturesBefore = transport.captureCount;

      final result = await canvas.pauseWhile(() async {
        await Future<void>.delayed(interval * 4);
        await canvas.refresh();
        return transport.captureCount;
      });

      expect(result, capturesBefore);
      await canvas.refresh();
      expect(transport.captureCount, capturesBefore + 1);
    });

    // Verifies: FR-CNV-006
    test('publishes a frame when only the scene changes', () async {
      await canvas.attach(transport);
      transport.scene = const Scene(
        width: 800,
        height: 600,
        devicePixelRatio: 3,
        elements: [],
      );

      await canvas.refresh();

      expect(canvas.frame.value?.id, 2);
      expect(canvas.frame.value?.scene, transport.scene);
    });

    // Verifies: FR-INS-007
    test('lets select only in an app that tracks widget creation', () async {
      await canvas.attach(transport);
      expect(canvas.isSelectable.value, isFalse);

      transport.agentInfo = const AgentInfo(
        protocolVersion: 1,
        isWidgetCreationTracked: false,
      );
      await canvas.attach(transport);
      expect(canvas.isSelectable.value, isFalse);

      transport.agentInfo = const AgentInfo(
        protocolVersion: 1,
        isWidgetCreationTracked: true,
      );
      await canvas.attach(transport);
      expect(canvas.isSelectable.value, isTrue);

      await canvas.detach();
      expect(canvas.isSelectable.value, isFalse);
    });
  });
}
