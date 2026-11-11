import 'dart:async';

import 'package:flutter/foundation.dart';

import 'frame.dart';
import 'frame_transport.dart';

/// Keeps the last frame of the running app for the canvas to show
/// (FR-CNV-001).
///
/// While a transport is attached, the controller asks it for a frame at a
/// fixed interval and publishes the frame when the image has changed.
final class CanvasController {
  /// Creates a controller that looks for a new frame every [interval].
  CanvasController({this.interval = const Duration(milliseconds: 500)});

  /// Time between two captures while the app runs.
  final Duration interval;

  final _frame = ValueNotifier<Frame?>(null);

  final _isLive = ValueNotifier(false);

  FrameTransport? _transport;

  Timer? _timer;

  /// Whether a capture is on its way. A tick that finds one is skipped.
  var _isCapturing = false;

  /// The last frame received, or `null` before the first one. It stays
  /// after the app ends, when [isLive] tells that it is out of date.
  ValueListenable<Frame?> get frame => _frame;

  /// Whether [frame] comes from an app that is running now.
  ValueListenable<bool> get isLive => _isLive;

  /// Starts showing the frames that [transport] brings, in place of the
  /// transport that was attached before.
  Future<void> attach(FrameTransport transport) async {
    await detach();
    _transport = transport;
    _isLive.value = true;
    _timer = Timer.periodic(interval, (_) => unawaited(refresh()));
    await refresh();
  }

  /// Stops asking for frames and closes the transport. The last frame
  /// stays, marked as out of date.
  Future<void> detach() async {
    _timer?.cancel();
    _timer = null;
    final transport = _transport;
    _transport = null;
    _isLive.value = false;
    await transport?.close();
  }

  /// Asks the transport for a frame now and publishes it when its image is
  /// not the one of the last frame.
  Future<void> refresh() async {
    final transport = _transport;
    if (transport == null || _isCapturing) return;
    _isCapturing = true;
    try {
      final pngBytes = await transport.capture();
      final last = _frame.value;
      if (pngBytes != null &&
          identical(transport, _transport) &&
          !listEquals(pngBytes, last?.pngBytes)) {
        _frame.value = Frame(id: (last?.id ?? 0) + 1, pngBytes: pngBytes);
      }
    } finally {
      _isCapturing = false;
    }
  }

  /// Releases the resources of the controller.
  Future<void> dispose() async {
    await detach();
    _frame.dispose();
    _isLive.dispose();
  }
}
