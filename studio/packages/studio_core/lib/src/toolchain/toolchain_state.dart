/// Where a supervised process is in its life.
enum ToolchainState {
  /// The first process is starting and is not ready yet.
  starting,

  /// The process is running and ready for use.
  running,

  /// The process ended unexpectedly and a new one is starting.
  restarting,

  /// The process keeps ending right after it starts, and the supervisor
  /// gave up.
  failed,

  /// The supervisor ended the process on request.
  stopped,
}
