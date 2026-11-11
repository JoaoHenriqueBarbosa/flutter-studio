import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/widgets.dart' show Image;
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/studio_core.dart';
import 'package:studio_shell/studio_shell.dart';

import '../support/workbench_fixture.dart';

/// A [FrameTransport] that always answers with the same image.
final class _OneFrameTransport implements FrameTransport {
  const _OneFrameTransport(this._image);

  final Uint8List _image;

  @override
  Future<CapturedFrame?> capture() async => (pngBytes: _image, scene: null);

  @override
  Future<void> close() async {}
}

/// A PNG image of one transparent pixel.
final _onePixelPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  group('CanvasPane', () {
    late CanvasController canvas;

    setUp(() {
      canvas = CanvasController(interval: const Duration(hours: 1));
    });

    Future<void> pumpPane(WidgetTester tester) => tester.pumpWidget(
      wrapForTest(
        CanvasPane(
          canvas: canvas,
          texts: lookupStudioLocalizations(const Locale('pt')),
        ),
      ),
    );

    // Verifies: FR-CNV-001, NFR-INTR-001
    testWidgets('invites to run the app before the first frame', (
      tester,
    ) async {
      await pumpPane(tester);

      expect(find.text('Execute o app para vê-lo aqui.'), findsOneWidget);
      await tester.runAsync(canvas.dispose);
    });

    // Verifies: FR-CNV-001, FR-CNV-008
    testWidgets('shows the frame, and marks it when the app ends', (
      tester,
    ) async {
      await pumpPane(tester);

      await tester.runAsync(
        () => canvas.attach(_OneFrameTransport(_onePixelPng)),
      );
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(find.textContaining('último quadro'), findsNothing);

      await tester.runAsync(canvas.detach);
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(find.textContaining('último quadro'), findsOneWidget);
      await tester.runAsync(canvas.dispose);
    });
  });
}
