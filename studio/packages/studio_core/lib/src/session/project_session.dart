import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:studio_protocol/studio_protocol.dart';

import '../dap/dap_request_failed.dart';
import '../document/document_change.dart';
import '../document/document_store.dart';
import '../document/project_file_watcher.dart';
import '../dtd/dtd_connection.dart';
import '../edit/edit_pipeline.dart';
import '../edit/widget_reader.dart';
import '../lsp/document_sync.dart';
import '../lsp/lsp_client.dart';
import '../project/flutter_project.dart';
import '../selection/selection_controller.dart';
import '../service/studio_service.dart';
import '../structure/source_trees.dart';
import '../toolchain/toolchain_supervisor.dart';
import 'analysis_server_child.dart';
import 'app_run.dart';
import 'tooling_daemon_child.dart';

/// An open project with its tools: daemon, analysis server, documents, the
/// `Studio` service and the run of the app (FR-PRJ-004).
final class ProjectSession {
  /// Creates the session of [project]. Nothing is started until [start].
  ProjectSession(this.project) : documents = DocumentStore(project.rootPath);

  /// The project of the session.
  final FlutterProject project;

  /// The documents of the project. Every edit goes through this store.
  final DocumentStore documents;

  /// The selection shared by the views and by the clients of the service.
  late final selection = SelectionController(documents);

  /// The `Studio` service of the project, which the session registers in
  /// the daemon. Every operation enters through it (ADR-0012).
  late final StudioApi service = StudioService(
    documents,
    selection,
    _pipeline,
    _reader,
  );

  late final _sync = DocumentSync(documents);

  late final _watcher = ProjectFileWatcher(project.rootPath, documents);

  /// The source trees of the files open in the analysis server
  /// (FR-INS-002).
  late final sourceTrees = SourceTrees(documents, _sync);

  late final _reader = WidgetReader(_sync, sourceTrees, () => _server);

  late final _pipeline = EditPipeline(
    documents,
    _reader,
    server: () => _server,
    requestReload: _requestReload,
  );

  final _supervisor = ToolchainSupervisor();

  final _daemonUri = ValueNotifier<Uri?>(null);

  final _appRun = ValueNotifier<AppRun?>(null);

  final _diagnostics = StreamController<FileDiagnostics>.broadcast();

  DtdConnection? _daemon;

  LspClient? _server;

  StreamSubscription<DocumentChange>? _changes;

  StreamSubscription<Set<String>>? _externalChanges;

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
  /// Completes when the `Studio` service is registered in the daemon and
  /// the server has registered its own. No code of the project runs.
  Future<void> start() async {
    selection.selection.addListener(_handleSelection);
    _changes = documents.changes.listen(_handleChange);
    // A file saved by another program is reloaded into the running app as
    // an edit of Studio is (FR-DOC-003).
    _externalChanges = _watcher.externalChanges.listen((_) => _requestReload());
    _watcher.start();
    await _supervisor.start(
      ToolingDaemonChild(project.sdk, _handleDaemonConnected),
    );
    await _supervisor.start(
      AnalysisServerChild(
        project,
        applyEdit: _pipeline.applyServerEdit,
        onConnected: _handleServerConnected,
      ),
    );
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
    selection.selection.removeListener(_handleSelection);
    await _changes?.cancel();
    await _externalChanges?.cancel();
    await _watcher.dispose();
    await sourceTrees.dispose();
    await _sync.dispose();
    await _server?.close();
    await _daemon?.close();
    await _supervisor.stop();
    await selection.dispose();
    await documents.dispose();
    await _diagnostics.close();
    _daemonUri.dispose();
    _appRun.dispose();
  }

  Future<void> _handleDaemonConnected(DtdConnection connection) async {
    _daemon = connection;
    await connection.serveStudio(service);
    _daemonUri.value = connection.uri;
    await _server?.connectToDtd(connection.uri);
  }

  Future<void> _handleServerConnected(LspClient client) async {
    _server = client;
    _sync.attach(client);
    sourceTrees.attach(client);
    // The subscription ends with the client, which closes its stream.
    unawaited(client.diagnostics.forEach(_diagnostics.add));
    final daemon = _daemon;
    if (daemon != null) await client.connectToDtd(daemon.uri);
  }

  /// Asks the running app to reload the code on disk (FR-DOC-002) and
  /// returns whether there was an app to ask.
  bool _requestReload() {
    final run = _appRun.value;
    if (run == null) return false;
    unawaited(_reload(run));
    return true;
  }

  Future<void> _reload(AppRun run) async {
    try {
      await run.hotReload();
    } on DapRequestFailed {
      // The run ended between the edit and the reload. The edit is on disk,
      // and the next run starts from it.
    }
  }

  /// Announces the selection to the inherited panels, as the active
  /// location of an editor, and to the clients of the service.
  ///
  /// The document is opened in the analysis server first, because the
  /// panels ask the server about the version that is announced.
  Future<void> _handleSelection() async {
    final selected = selection.selection.value;
    final daemon = _daemon;
    if (daemon == null) return;
    if (selected != null) {
      _sync.ensureOpen(selected.filePath);
      await daemon.postActiveLocation(
        filePath: selected.filePath,
        position: selected.position,
        documentVersion: selected.documentVersion,
      );
    }
    await daemon.postStudioEvent(
      StudioEvent.selectionChanged,
      SelectionChanged(selection: await service.getSelection()).toJson(),
    );
  }

  Future<void> _handleChange(DocumentChange change) async {
    await _daemon?.postStudioEvent(
      StudioEvent.documentChanged,
      DocumentChanged(
        uri: '${Uri.file(change.filePath)}',
        documentVersion: change.document.version,
        origin: change.origin,
      ).toJson(),
    );
  }
}
