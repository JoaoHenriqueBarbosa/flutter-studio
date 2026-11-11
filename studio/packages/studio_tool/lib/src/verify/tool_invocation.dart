/// Command line of an external tool.
final class ToolInvocation {
  /// Creates the command line that runs [executable] with [arguments], in
  /// the environment of this process changed by [environment].
  const ToolInvocation(
    this.executable,
    this.arguments, {
    this.environment = const {},
  });

  /// Name of the executable, resolved through the `PATH` variable.
  final String executable;

  /// Arguments passed to the executable, in order.
  final List<String> arguments;

  /// Variables that the tool sees with these values, whatever this process
  /// has in them.
  final Map<String, String> environment;

  @override
  String toString() => [executable, ...arguments].join(' ');
}
