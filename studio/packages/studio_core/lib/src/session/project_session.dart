import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../dap/dap_request_failed.dart';
import '../document/document_change.dart';
import '../document/document_store.dart';
import '../document/edit_failure.dart';
import '../document/text_edit.dart';
import '../document/workspace_edit.dart';
import '../dtd/dtd_connection.dart';
import '../lsp/lsp_client.dart';
import '../project/flutter_project.dart';
import '../toolchain/toolchain_supervisor.dart';
import 'analysis_server_child.dart';
import 'app_run.dart';
import 'tooling_daemon_child.dart';

/// An open project with its tools: daemon, analysis server, documents and
/// the run of the app (FR-PRJ-004).
final class ProjectSession {
  /// Creates the session of [project]. Nothing is started until [start].
  ProjectSession(this.project) : documents = DocumentStore(project.rootPath);

  /// The project of the session.
  final FlutterProject project;

  /// The documents of the project. Every edit goes through this store.
  final DocumentStore documents;

  final _supervisor = ToolchainSupervisor();

  final _daemonUri = ValueNotifier<Uri?>(null);

  final _appRun = ValueNotifier<AppRun?>(null);

  final _diagnostics = StreamController<FileDiagnostics>.broadcast();

  DtdConnection? _daemon;

  LspClient? _server;

  ({String filePath, DocumentPosition position})? _activeLocation;

  StreamSubscription<DocumentChange>? _changes;

  /// Address of the Dart Tooling Daemon, or `null` while it is not running.
  ValueListenable<Uri?> get daemonUri => _daemonUri;

  /// The current run of the app, or `null` when the app is not running.
  ValueListenable<AppRun?> get appRun => _appRun;

  /// Diagnostics of the project, as the analysis server publishes them.
  Stream<FileDiagnostics> get diagnostics => _diagnostics.stream;

  /// The supervisor of the tools, for whoever shows their state.
  ToolchainSupervisor get supervisor => _supervisor;

  /// Starts the daemon, then the analysis server, and pairs the two.
  ///
  /// Completes when the server has registered its service in the daemon.
  /// No code of the project runs.
  Future<void> start() async {
    _changes = documents.changes.listen(_handleChange);
    await _supervisor.start(
      ToolingDaemonChild(project.sdk, _handleDaemonConnected),
    );
    await _supervisor.start(
      AnalysisServerChild(
        project,
        applyEdit: _applyEdit,
        onConnected: _handleServerConnected,
      ),
    );
  }

  /// Announces to the tools that the active location is [position] in the
  /// file at [filePath]. The location is announced again after each edit.
  Future<void> selectLocation({
    required String filePath,
    required DocumentPosition position,
  }) async {
    _activeLocation = (filePath: filePath, position: position);
    await _daemon?.postActiveLocation(filePath: filePath, position: position);
  }

  /// Builds and starts the app on the device [deviceId].
  ///
  /// Completes when the debug adapter accepts the launch. A run that is
  /// already in progress is ended first.
  Future<AppRun> startApp({required String deviceId}) async {
    await stopApp();
    final run = await AppRun.start(project, deviceId: deviceId);
    _appRun.value = run;
    unawaited(
      run.ended.then((_) {
        if (_appRun.value == run) _appRun.value = null;
      }),
    );
    return run;
  }

  /// Ends the run of the app, if there is one.
  Future<void> stopApp() async {
    final run = _appRun.value;
    _appRun.value = null;
    await run?.stop();
  }

  /// Ends the app and the tools and releases the resources of the session.
  Future<void> close() async {
    await stopApp();
    await _changes?.cancel();
    await _server?.close();
    await _daemon?.close();
    await _supervisor.stop();
    await documents.dispose();
    await _diagnostics.close();
    _daemonUri.dispose();
    _appRun.dispose();
  }

  Future<void> _handleDaemonConnected(DtdConnection connection) async {
    _daemon = connection;
    _daemonUri.value = connection.uri;
    await _server?.connectToDtd(connection.uri);
  }

  Future<void> _handleServerConnected(LspClient client) async {
    _server = client;
    // The subscription ends with the client, which closes its stream.
    unawaited(client.diagnostics.forEach(_diagnostics.add));
    final daemon = _daemon;
    if (daemon != null) await client.connectToDtd(daemon.uri);
  }

  Future<bool> _applyEdit(WorkspaceEdit edit) async {
    try {
      await documents.apply(edit);
      return true;
    } on EditFailure {
      return false;
    } on FileSystemException {
      return false;
    }
  }

  /// Reloads the app after the file is on disk (FR-DOC-002) and announces
  /// the active location again, so that the tools read the new text.
  Future<void> _handleChange(DocumentChange change) async {
    try {
      await _appRun.value?.hotReload();
    } on DapRequestFailed {
      // The run ended between the edit and the reload. The edit is on disk,
      // and the next run starts from it.
    }
    final location = _activeLocation;
    if (location != null) {
      await _daemon?.postActiveLocation(
        filePath: location.filePath,
        position: location.position,
      );
    }
  }
}
