import 'package:devtools_app/devtools_app.dart';
import 'package:devtools_app_shared/service.dart';
import 'package:devtools_app_shared/utils.dart';
import 'package:material_ui/material_ui.dart';
import 'package:studio_core/studio_core.dart';
import 'package:studio_shell/studio_shell.dart';

/// Creates an adapter over managers of DevTools that are connected to
/// nothing.
InheritedDevTools createDisconnectedDevTools() {
  setGlobal(OfflineDataController, OfflineDataController());
  return InheritedDevTools(
    daemonManager: DTDManager(),
    serviceConnection: ServiceConnectionManager(),
    screenControllers: ScreenControllers(),
  );
}

/// Creates a controller that finds no SDK, over [devTools].
WorkbenchController createWorkbenchController(InheritedDevTools devTools) =>
    WorkbenchController(
      const ProjectLoader(SdkLocator(environment: {'PATH': ''})),
      devTools,
    );

/// Wraps [child] in what the widgets of the workbench expect above them.
Widget wrapForTest(Widget child) => MaterialApp(home: Scaffold(body: child));
