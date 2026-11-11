/// The debug adapter answered a request with a failure.
final class DapRequestFailed implements Exception {
  /// Creates the failure of [command], with the [message] of the adapter.
  const DapRequestFailed(this.command, this.message);

  /// Command of the request that failed.
  final String command;

  /// Reason given by the adapter.
  final String message;

  @override
  String toString() => 'Request $command failed: $message';
}
