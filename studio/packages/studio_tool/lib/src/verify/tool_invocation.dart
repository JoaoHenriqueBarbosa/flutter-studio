/// Command line of an external tool.
final class ToolInvocation {
  /// Creates the command line that runs [executable] with [arguments].
  const ToolInvocation(this.executable, this.arguments);

  /// Name of the executable, resolved through the `PATH` variable.
  final String executable;

  /// Arguments passed to the executable, in order.
  final List<String> arguments;

  @override
  String toString() => [executable, ...arguments].join(' ');
}
