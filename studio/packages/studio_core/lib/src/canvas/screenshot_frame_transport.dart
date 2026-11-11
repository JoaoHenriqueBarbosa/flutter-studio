import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import 'frame_transport.dart';

/// A [FrameTransport] that asks the engine for a screenshot through the VM
/// Service of the app.
///
/// It is the first rung of ADR-0009 without the design agent: it works on
/// every device, and each frame is encoded as PNG and copied through the
/// main memory.
final class ScreenshotFrameTransport implements FrameTransport {
  ScreenshotFrameTransport._(this._service);

  /// Method of the engine that renders the current frame of the app.
  static const _screenshotMethod = '_flutter.screenshot';

  static const _imageKey = 'screenshot';

  final VmService _service;

  /// Connects to the VM Service of the app at [vmServiceUri], the address
  /// that the debug adapter reports.
  static Future<ScreenshotFrameTransport> connect(Uri vmServiceUri) async {
    final webSocketUri = vmServiceUri.replace(
      scheme: vmServiceUri.isScheme('https') ? 'wss' : 'ws',
      pathSegments: [
        ...vmServiceUri.pathSegments.where((segment) => segment.isNotEmpty),
        if (vmServiceUri.pathSegments.lastOrNull != 'ws') 'ws',
      ],
    );
    return ScreenshotFrameTransport._(
      await vmServiceConnectUri('$webSocketUri'),
    );
  }

  @override
  Future<Uint8List?> capture() async {
    try {
      final response = await _service.callMethod(_screenshotMethod);
      return switch (response.json?[_imageKey]) {
        final String image => base64Decode(image),
        _ => null,
      };
    } on RPCError {
      // The app ended, or has no frame to show yet.
      return null;
    }
  }

  @override
  Future<void> close() => _service.dispose();
}
