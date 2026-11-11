import 'package:devtools_app/devtools_app.dart';
import 'package:devtools_app_shared/service.dart';
import 'package:devtools_app_shared/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:studio_core/studio_core.dart';

/// Adapter over the inherited DevTools application.
///
/// Applies the Adapter pattern: the shell asks for what it needs in terms
/// of Studio, and this class translates to the managers and controllers of
/// DevTools, which are handed to it by the composition root (CS-DSN-006).
final class InheritedDevTools extends DisposableController
    with AutoDisposeControllerMixin {
  /// Creates the adapter over the managers of the running DevTools.
  InheritedDevTools({
    required this.daemonManager,
    required this._serviceConnection,
    required this._screenControllers,
  }) {
    addAutoDisposeListener(appConnection, _handleConnectionChanged);
  }

  /// Parameter of the DevTools route that names the VM Service of the app.
  static const _vmServiceParameter = 'uri';

  /// Connection of DevTools with the Dart Tooling Daemon. The inherited
  /// panels that talk to the daemon receive this manager.
  final DTDManager daemonManager;

  final ServiceConnectionManager _serviceConnection;

  final ScreenControllers _screenControllers;

  final _inspector = ValueNotifier<InspectorController?>(null);

  final _selectedLocation = ValueNotifier<SourceLocation?>(null);

  /// Whether DevTools is connected to the VM Service of an app.
  ValueListenable<ConnectedState> get appConnection =>
      _serviceConnection.serviceManager.connectedState;

  /// The controller of the inherited inspector, or `null` while DevTools is
  /// not connected to an app.
  ValueListenable<InspectorController?> get inspector => _inspector;

  /// Where the widget selected in the inspector is created, or `null` when
  /// nothing is selected or the widget has no creation location.
  ///
  /// Lines and characters count from zero.
  ValueListenable<SourceLocation?> get selectedLocation => _selectedLocation;

  /// Connects DevTools to the daemon at [daemonUri].
  Future<void> connectDaemon(Uri daemonUri) => daemonManager.connect(daemonUri);

  /// Connects DevTools to the app whose VM Service is at [vmServiceUri].
  ///
  /// [router] is the delegate of the DevTools route, which owns the
  /// connection.
  Future<void> connectApp(DevToolsRouterDelegate router, Uri vmServiceUri) =>
      router.updateArgsIfChanged({_vmServiceParameter: '$vmServiceUri'});

  /// Disconnects DevTools from the app.
  Future<void> disconnectApp(DevToolsRouterDelegate router) =>
      router.clearUriParameter();

  @override
  void dispose() {
    _inspector.dispose();
    _selectedLocation.dispose();
    super.dispose();
  }

  void _handleConnectionChanged() {
    if (_inspector.value != null) cancelListener(_handleSelectionChanged);
    _inspector.value = null;
    _selectedLocation.value = null;
    _attachInspector();
  }

  /// Starts following the selection of the inspector of the connected app.
  ///
  /// DevTools registers the controllers of its screens when it rebuilds
  /// after the connection, which is later than the change of
  /// [appConnection]. Until then this method tries again after each frame.
  void _attachInspector() {
    if (!appConnection.value.connected || _inspector.value != null) return;
    if (!_screenControllers.isRegistered<InspectorScreenController>()) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _attachInspector());
      return;
    }
    final inspector = _screenControllers
        .lookup<InspectorScreenController>()
        .inspectorController;
    _inspector.value = inspector;
    // The creation location is not in the node of the tree: the inspector
    // loads it with the properties of the selected widget.
    addAutoDisposeListener(
      inspector.selectedNodeProperties,
      _handleSelectionChanged,
    );
  }

  void _handleSelectionChanged() {
    final location =
        _inspector.value?.selectedNodeProperties.value.creationLocation;
    final file = location?.getFile();
    if (location == null || file == null) {
      _selectedLocation.value = null;
      return;
    }
    // The inspector counts lines and columns from one.
    _selectedLocation.value = (
      filePath: file.startsWith('file:') ? Uri.parse(file).toFilePath() : file,
      position: (
        line: location.getLine() - 1,
        character: location.getColumn() - 1,
      ),
    );
  }
}
