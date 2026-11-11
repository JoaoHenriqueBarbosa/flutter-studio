import 'dart:convert';

import 'package:studio_protocol/studio_protocol.dart';
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

  /// The isolate of the app that answers for the agent, once it is known.
  String? _isolateId;

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
  Future<CapturedFrame?> capture() async {
    try {
      final response = await _service.callMethod(_screenshotMethod);
      return switch (response.json?[_imageKey]) {
        final String image => (
          pngBytes: base64Decode(image),
          scene: await _readScene(),
        ),
        _ => null,
      };
    } on RPCError {
      // The app ended, or has no frame to show yet.
      return null;
    } on FormatException {
      // The agent answered in a form that this Studio does not read.
      return null;
    }
  }

  @override
  Future<AgentInfo?> readAgentInfo() async {
    final answer = await _askAgent(StudioAgentExtension.hello);
    return answer == null ? null : AgentInfo.fromJson(answer);
  }

  /// Completes with the scene mirror that the design agent gives, or with
  /// `null` when the app has no agent.
  Future<Scene?> _readScene() async {
    final answer = await _askAgent(StudioAgentExtension.scene);
    return answer == null ? null : Scene.fromJson(answer);
  }

  /// Calls [extension] of the design agent and completes with its answer
  /// in JSON form, or with `null` when the app has no agent or the answer
  /// does not come.
  Future<Map<String, Object?>?> _askAgent(
    StudioAgentExtension extension,
  ) async {
    try {
      final isolateId = _isolateId ??=
          (await _service.getVM()).isolates?.firstOrNull?.id;
      if (isolateId == null) return null;
      final response = await _service.callServiceExtension(
        extension.method,
        isolateId: isolateId,
      );
      return response.json;
    } on RPCError {
      // No agent in this app, or the isolate was replaced by a restart:
      // the next call looks for the isolate again.
      _isolateId = null;
      return null;
    }
  }

  @override
  Future<void> close() => _service.dispose();
}
