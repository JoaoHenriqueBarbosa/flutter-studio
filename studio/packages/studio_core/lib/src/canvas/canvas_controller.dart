import 'dart:async';

import 'package:flutter/foundation.dart';

import 'frame.dart';
import 'frame_transport.dart';

/// Keeps the last frame of the running app for the canvas to show
/// (FR-CNV-001).
///
/// While a transport is attached, the controller asks it for a frame at a
/// fixed interval and publishes the frame when the image or the scene has
/// changed.
final class CanvasController {
  /// Creates a controller that looks for a new frame every [interval].
  CanvasController({this.interval = const Duration(milliseconds: 500)});

  /// Time between two captures while the app runs.
  final Duration interval;

  final _frame = ValueNotifier<Frame?>(null);

  final _isLive = ValueNotifier(false);

  FrameTransport? _transport;

  Timer? _timer;

  /// The capture that is on its way, or `null`. A tick that finds one is
  /// skipped.
  Future<void>? _capture;

  /// How many callers of [pauseWhile] are holding the captures back.
  var _pauseCount = 0;

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
  /// not the one of the last frame. Does nothing while a capture is on its
  /// way or the captures are held back by [pauseWhile].
  Future<void> refresh() async {
    final transport = _transport;
    if (transport == null || _capture != null || _pauseCount > 0) return;
    final capture = _capture = _captureFrom(transport);
    try {
      await capture;
    } finally {
      _capture = null;
    }
  }

  /// Runs [action] with no capture in progress, and completes with its
  /// result.
  ///
  /// The capture on its way ends first, and none starts until [action]
  /// completes. A hot reload has to run this way: the engine of the design
  /// host stops answering when it is asked for a frame while the code of
  /// the app is being replaced.
  Future<T> pauseWhile<T>(Future<T> Function() action) async {
    _pauseCount++;
    try {
      await _capture;
      return await action();
    } finally {
      _pauseCount--;
    }
  }

  /// Releases the resources of the controller.
  Future<void> dispose() async {
    await detach();
    _frame.dispose();
    _isLive.dispose();
  }

  Future<void> _captureFrom(FrameTransport transport) async {
    final captured = await transport.capture();
    final last = _frame.value;
    if (captured == null || !identical(transport, _transport)) return;
    final isSameImage = listEquals(captured.pngBytes, last?.pngBytes);
    if (isSameImage && captured.scene == last?.scene) return;
    _frame.value = Frame(
      id: (last?.id ?? 0) + 1,
      // Keeps the list that the widgets already decoded.
      pngBytes: isSameImage
          ? last?.pngBytes ?? captured.pngBytes
          : captured.pngBytes,
      scene: captured.scene,
    );
  }
}
