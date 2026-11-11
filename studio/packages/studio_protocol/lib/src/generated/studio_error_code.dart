// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

/// The errors of the `Studio` service, in the range that JSON-RPC 2.0
/// reserves for the implementation.
enum StudioErrorCode {
  /// Comes with: the current version of the document.
  staleDocument(-32001, 'StaleDocument'),

  /// Comes with: the URI that is outside the roots of the project.
  notInProject(-32002, 'NotInProject'),

  /// Comes with: the diagnostics that the edit would add.
  editRejected(-32003, 'EditRejected'),

  /// Comes with: the session identifier that was not found.
  noSession(-32004, 'NoSession'),

  /// Comes with: the reason why the target does not accept the operation.
  unsupportedTarget(-32005, 'UnsupportedTarget'),

  /// Comes with: the name of the process that is not running.
  toolchainUnavailable(-32006, 'ToolchainUnavailable');

  const StudioErrorCode(this.code, this.message);

  /// Number of the error on the wire.
  final int code;

  /// Name of the error, sent as the message.
  final String message;
}
