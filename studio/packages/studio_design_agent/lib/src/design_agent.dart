import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:studio_protocol/studio_protocol.dart';

import 'scene_collector.dart';

/// The design agent: it answers, inside the app of the project, what the
/// shell of Studio asks through the service extensions of the contract.
final class DesignAgent {
  /// Creates the agent of the app whose project sources are under
  /// [_projectRootUris], `file:` URIs of directories that end with a slash.
  const DesignAgent(this._projectRootUris);

  /// Version of the protocol between the shell and the agent.
  static const protocolVersion = 1;

  final List<String> _projectRootUris;

  /// Initializes the binding of the app and registers the extensions of
  /// the agent. It is called once, before the `main` of the project.
  void start() {
    final binding = WidgetsFlutterBinding.ensureInitialized();
    final collector = SceneCollector(binding, _projectRootUris);
    _register(
      StudioAgentExtension.hello,
      () => const AgentInfo(protocolVersion: protocolVersion).toJson(),
    );
    _register(StudioAgentExtension.scene, () => collector.collect().toJson());
  }

  void _register(
    StudioAgentExtension extension,
    Map<String, Object?> Function() answer,
  ) {
    developer.registerExtension(
      extension.method,
      (method, parameters) async =>
          developer.ServiceExtensionResponse.result(jsonEncode(answer())),
    );
  }
}
