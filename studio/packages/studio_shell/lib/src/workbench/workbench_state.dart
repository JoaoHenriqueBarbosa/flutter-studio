import 'package:studio_core/studio_core.dart';

/// What the workbench has open.
sealed class WorkbenchState {
  const WorkbenchState();
}

/// No project is open.
final class WorkbenchEmpty extends WorkbenchState {
  /// Creates the state of a workbench with no project.
  const WorkbenchEmpty();
}

/// A project is being opened and its tools are starting.
final class WorkbenchOpening extends WorkbenchState {
  /// Creates the state for the project at [projectPath].
  const WorkbenchOpening(this.projectPath);

  /// Directory being opened.
  final String projectPath;
}

/// The last attempt to open a project failed.
final class WorkbenchFailed extends WorkbenchState {
  /// Creates the state for an attempt that ended with [failure].
  const WorkbenchFailed(this.failure);

  /// Why the project was not opened.
  final ProjectOpenFailure failure;
}

/// A project is open and its tools are running.
final class WorkbenchReady extends WorkbenchState {
  /// Creates the state for the project of [session].
  const WorkbenchReady(this.session);

  /// The session of the open project.
  final ProjectSession session;
}
