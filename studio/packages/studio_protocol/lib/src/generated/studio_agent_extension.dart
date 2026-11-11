// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

/// The service extensions that the design agent registers in the app.
enum StudioAgentExtension {
  /// Returns the version of the protocol of the design agent.
  hello('ext.studio.agent.hello'),

  /// Returns the scene mirror of the frame on screen: the geometry and the
  /// creation location of each element created in the project.
  scene('ext.studio.agent.scene');

  const StudioAgentExtension(this.method);

  /// Full name of the extension in the VM Service.
  final String method;
}
