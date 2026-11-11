/// The analysis server refused a request, or was gone before it answered.
final class LspRequestFailed implements Exception {
  /// Creates the failure of the request [method], explained by [message].
  const LspRequestFailed(this.method, this.message);

  /// Name of the method that failed.
  final String method;

  /// What the server reported.
  final String message;

  @override
  String toString() => '$method failed: $message';
}
