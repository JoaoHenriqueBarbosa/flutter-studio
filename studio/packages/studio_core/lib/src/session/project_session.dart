import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:studio_protocol/studio_protocol.dart';

import '../canvas/canvas_controller.dart';
import '../canvas/screenshot_frame_transport.dart';
import '../dap/dap_request_failed.dart';
import '../document/document_change.dart';
import '../document/document_store.dart';
import '../document/project_file_watcher.dart';
import '../dtd/dtd_connection.dart';
import '../edit/edit_pipeline.dart';
import '../edit/widget_reader.dart';
import '../host/design_host_project.dart';
import '../lsp/document_sync.dart';
import '../lsp/lsp_client.dart';
import '../project/flutter_project.dart';
import '../selection/selection_controller.dart';
import '../service/studio_service.dart';
import '../structure/source_trees.dart';
import '../toolchain/toolchain_supervisor.dart';
import 'analysis_server_child.dart';
import 'app_run.dart';
import 'run_target.dart';
import 'tooling_daemon_child.dart';

/// An open project with its tools: daemon, analysis server, documents, the
/// `Studio` service and the run of the app (FR-PRJ-004).
final class ProjectSession {
  /// Creates the session of [project]. Nothing is started until [start].
  ///
  /// The frames of the app go to [canvas], or to a canvas of the session
  /// when none is given.
  ///
  /// [studioPackagesPath] is the directory with the sources of the design
  /// agent. With it, the design host runs the app through a generated host
  /// project that starts the agent (ADR-0008); without it, the app runs as
  /// it is, and the canvas shows frames with no scene.
  ProjectSession(
    this.project, {
    CanvasController? canvas,
    String? studioPackagesPath,
  }) : documents = DocumentStore(project.rootPath),
       canvas = canvas ?? CanvasController(),
       _designHost = studioPackagesPath == null
           ? null
           : DesignHostProject(project, studioPackagesPath);

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

  /// The frames of the running app (FR-CNV-001).
  final CanvasController canvas;

  final DesignHostProject? _designHost;

  /// The source trees of the files open in the analysis server
  /// (FR-INS-002).
  late final sourceTrees = SourceTrees(documents, _sync);

  late final _reader = WidgetReader(
    _sync,
    sourceTrees,
    () => _server,
    runningScene: () => canvas.isLive.value ? canvas.frame.value?.scene : null,
  );

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

  /// Builds and starts the app on [target].
  ///
  /// Completes when the debug adapter accepts the launch. A run that is
  /// already in progress is ended first. The canvas shows the frames of the
  /// app from the moment it starts until the run ends.
  Future<AppRun> startApp({required RunTarget target}) async {
    await stopApp();
    final run = await AppRun.start(
      project.sdk,
      rootPath: await _rootPathFor(target),
      target: target,
    );
    _appRun.value = run;
    unawaited(_showOnCanvas(run));
    unawaited(
      run.ended.then((_) async {
        if (_appRun.value != run) return;
        _appRun.value = null;
        await canvas.detach();
      }),
    );
    return run;
  }

  /// Returns the directory of the Flutter project to run on [target]: the
  /// generated host project on the design host, when the session has the
  /// sources of the agent, and the project of the user otherwise.
  Future<String> _rootPathFor(RunTarget target) async {
    final designHost = _designHost;
    if (designHost == null || target != const RunTarget.designHost()) {
      return project.rootPath;
    }
    await designHost.generate();
    return designHost.rootPath;
  }

  /// Restarts the running app with the code on disk, losing its state.
  /// Does nothing when the app is not running.
  ///
  /// Throws [DapRequestFailed] when the debug adapter refuses.
  Future<void> restartApp() async {
    final run = _appRun.value;
    if (run == null) return;
    await canvas.pauseWhile(run.hotRestart);
    await canvas.refresh();
  }

  /// Ends the run of the app, if there is one.
  Future<void> stopApp() async {
    final run = _appRun.value;
    _appRun.value = null;
    await canvas.detach();
    await run?.stop();
  }

  /// Ends the app and the tools and releases the resources of the session.
  Future<void> close() async {
    await stopApp();
    await canvas.dispose();
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

  /// Attaches the canvas to [run] once the app has started, unless the run
  /// ended or gave place to another one in the meantime.
  Future<void> _showOnCanvas(AppRun run) async {
    final vmServiceUri = await Future.any<Uri?>([
      run.vmServiceUri,
      run.ended.then((_) => null),
    ]);
    if (vmServiceUri == null || _appRun.value != run) return;
    try {
      await canvas.attach(await ScreenshotFrameTransport.connect(vmServiceUri));
    } on IOException {
      // The app ended while the canvas was connecting to it.
    }
  }

  Future<void> _reload(AppRun run) async {
    try {
      await canvas.pauseWhile(run.hotReload);
      await canvas.refresh();
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
