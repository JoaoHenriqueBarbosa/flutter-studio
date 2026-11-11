import 'dart:async';
import 'dart:io';

import 'package:devtools_app/devtools_app.dart';
import 'package:devtools_app_shared/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:studio_core/studio_core.dart';
import 'package:studio_protocol/studio_protocol.dart';

import '../inherited/inherited_dev_tools.dart';
import 'app_run_status.dart';
import 'workbench_state.dart';

/// Opens the project, runs its app and links the selection of the inherited
/// inspector to the tools of the project.
final class WorkbenchController extends DisposableController
    with AutoDisposeControllerMixin {
  /// Creates a controller that opens projects with [_loader] and reaches
  /// the inherited panels through [_devTools].
  WorkbenchController(this._loader, this._devTools) {
    addAutoDisposeListener(_devTools.selectedLocation, _handleSelection);
  }

  final ProjectLoader _loader;

  final InheritedDevTools _devTools;

  final _state = ValueNotifier<WorkbenchState>(const WorkbenchEmpty());

  final _runStatus = ValueNotifier(AppRunStatus.stopped);

  final _output = ValueNotifier('');

  /// What the workbench has open.
  ValueListenable<WorkbenchState> get state => _state;

  /// Where the app is in a run.
  ValueListenable<AppRunStatus> get runStatus => _runStatus;

  /// Everything the build and the app wrote in the current run
  /// (FR-RUN-003).
  ValueListenable<String> get output => _output;

  ProjectSession? get _session => switch (_state.value) {
    WorkbenchReady(:final session) => session,
    _ => null,
  };

  /// Opens the directory at [projectPath] as the project of the workbench
  /// and starts its tools. A project that was open is closed first.
  ///
  /// Completes when [state] is either ready or failed.
  Future<void> openProject(String projectPath) async {
    await closeProject();
    _state.value = WorkbenchOpening(projectPath);
    try {
      final session = ProjectSession(_loader.load(projectPath));
      await session.start();
      final daemonUri = session.daemonUri.value;
      if (daemonUri != null) await _devTools.connectDaemon(daemonUri);
      _state.value = WorkbenchReady(session);
    } on ProjectOpenFailure catch (failure) {
      _state.value = WorkbenchFailed(failure);
    }
  }

  /// Builds and starts the app on this machine, and connects the inherited
  /// panels to it. Does nothing when no project is open or a run exists.
  Future<void> runApp(DevToolsRouterDelegate router) async {
    final session = _session;
    if (session == null || _runStatus.value != AppRunStatus.stopped) return;
    _runStatus.value = AppRunStatus.starting;
    _output.value = '';
    try {
      final run = await session.startApp(deviceId: Platform.operatingSystem);
      // The stream closes when the run ends, which ends the subscription.
      unawaited(run.output.forEach(_appendOutput));
      unawaited(run.ended.then((_) => _handleRunEnded(router)));
      final vmServiceUri = await Future.any<Uri?>([
        run.vmServiceUri,
        run.ended.then((_) => null),
      ]);
      if (vmServiceUri == null) return;
      await _devTools.connectApp(router, vmServiceUri);
      _runStatus.value = AppRunStatus.running;
    } on DapRequestFailed catch (failure) {
      _appendOutput('$failure\n');
      _runStatus.value = AppRunStatus.stopped;
    } on ProcessException catch (failure) {
      _appendOutput('$failure\n');
      _runStatus.value = AppRunStatus.stopped;
    }
  }

  /// Restarts the running app with the code on disk.
  Future<void> restartApp() async {
    try {
      await _session?.appRun.value?.hotRestart();
    } on DapRequestFailed catch (failure) {
      _appendOutput('$failure\n');
    }
  }

  /// Undoes the last edit of the open project, through the service.
  Future<void> undo() => _editThroughService((studio) => studio.undo());

  /// Redoes the last undone edit of the open project, through the service.
  Future<void> redo() => _editThroughService((studio) => studio.redo());

  /// Ends the run of the app, if there is one.
  ///
  /// The inherited panels are disconnected first: they call the app while
  /// they are disposed, and fail when the app is already gone.
  Future<void> stopApp(DevToolsRouterDelegate router) async {
    await _devTools.disconnectApp(router);
    await _session?.stopApp();
  }

  /// Ends the app and the tools of the open project.
  ///
  /// Completes when their processes have ended. The shell awaits this
  /// before it exits, so that no process of the SDK outlives it.
  Future<void> closeProject() async {
    final session = _session;
    _state.value = const WorkbenchEmpty();
    await session?.close();
  }

  @override
  void dispose() {
    unawaited(_session?.close());
    _state.dispose();
    _runStatus.dispose();
    _output.dispose();
    super.dispose();
  }

  /// Runs [operation] on the service of the open project and writes a
  /// refusal to the output.
  Future<void> _editThroughService(
    Future<EditResult> Function(StudioApi studio) operation,
  ) async {
    final session = _session;
    if (session == null) return;
    try {
      await operation(session.service);
    } on StudioFault catch (fault) {
      _appendOutput('$fault\n');
    }
  }

  void _appendOutput(String text) {
    _output.value += text;
  }

  Future<void> _handleRunEnded(DevToolsRouterDelegate router) async {
    _runStatus.value = AppRunStatus.stopped;
    await _devTools.disconnectApp(router);
  }

  /// Announces to the tools of the project the widget selected in the
  /// inspector, when it is created in a file of the project.
  void _handleSelection() {
    final session = _session;
    final location = _devTools.selectedLocation.value;
    if (session == null || location == null) return;
    if (!path.isWithin(session.project.rootPath, location.filePath)) return;
    session.selection.select(location);
  }
}
