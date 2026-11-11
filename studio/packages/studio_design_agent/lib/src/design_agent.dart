import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:studio_package_assets/studio_package_assets.dart';
import 'package:studio_protocol/studio_protocol.dart';

import 'scene_collector.dart';

/// The design agent: it answers, inside the app of the project, what the
/// shell of Studio asks through the service extensions of the contract.
final class DesignAgent {
  /// Creates the agent of the app of the package [projectName], whose
  /// sources are under [projectRootUris], `file:` URIs of directories that
  /// end with a slash.
  const DesignAgent({required this.projectName, required this.projectRootUris});

  /// Version of the protocol between the shell and the agent.
  static const protocolVersion = 1;

  /// Name of the package of the project, as its `pubspec.yaml` declares.
  final String projectName;

  /// Where the sources of the project are.
  final List<String> projectRootUris;

  /// Prepares the app to run inside the host project and registers the
  /// extensions of the agent. It is called once, before the `main` of the
  /// project, which has to start after the returned future completes.
  ///
  /// In the host, the project is a dependency: its assets and its fonts are
  /// bundled under the prefix of its package. The binding and the fonts
  /// set up here let the code of the project find them by the names it
  /// uses (ADR-0008).
  Future<void> start() async {
    final binding = PackageAssetBinding.ensureInitialized(
      packageName: projectName,
    );
    await PackageFontRegistry(
      rootBundle,
      packageName: projectName,
    ).registerAliases();
    final collector = SceneCollector(binding, projectRootUris);
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
