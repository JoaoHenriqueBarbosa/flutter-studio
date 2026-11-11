/// Where the app of the open project is in a run.
enum AppRunStatus {
  /// The app is not running.
  stopped,

  /// The app is being built and started.
  starting,

  /// The app is running and DevTools is connected to it.
  running,
}
