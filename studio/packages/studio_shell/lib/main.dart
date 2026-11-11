import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:devtools_app/devtools_app.dart';
import 'package:devtools_app/initialization.dart';
import 'package:devtools_app_shared/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:studio_core/studio_core.dart';

import 'src/inherited/inherited_dev_tools.dart';
import 'src/inherited_assets/inherited_font_registry.dart';
import 'src/l10n/studio_localizations.dart';
import 'src/studio_widgets_binding.dart';
import 'src/workbench/studio_screen.dart';
import 'src/workbench/workbench_controller.dart';
import 'src/workbench/workbench_view.dart';

/// Starts the shell on top of the inherited DevTools application.
///
/// The first of [arguments], when present, is the directory of a project to
/// open at startup.
void main(List<String> arguments) {
  BindingBase.debugZoneErrorsAreFatal = true;
  setGlobal(
    DevToolsEnvironmentParameters,
    ExternalDevToolsEnvironmentParameters(),
  );
  final texts = lookupStudioLocalizations(_interfaceLocale());
  // Both are created after DevTools has set the globals they are built
  // from, and before the first frame builds the screen that reads them.
  late final InheritedDevTools devTools;
  late final WorkbenchController controller;
  runDevTools(
    ensureBindingInitialized: StudioWidgetsBinding.ensureInitialized,
    screens: [
      DevToolsScreen<DevToolsScreenController>(
        StudioScreen(
          (context) => WorkbenchView(
            controller: controller,
            devTools: devTools,
            texts: texts,
          ),
        ),
      ),
      ...defaultScreens(),
    ],
    onDevToolsInitialized: () async {
      await InheritedFontRegistry(
        rootBundle,
        packageName: inheritedPackageName,
      ).registerAliases();
      devTools = InheritedDevTools(
        daemonManager: dtdManager,
        serviceConnection: serviceConnection,
        screenControllers: screenControllers,
      );
      controller = WorkbenchController(
        ProjectLoader(SdkLocator(environment: Platform.environment)),
        devTools,
      );
      _closeProjectOnExit(controller);
      final projectPath = arguments.firstOrNull;
      if (projectPath != null) unawaited(controller.openProject(projectPath));
    },
  );
}

/// Closes the open project before the shell exits, whether the user closes
/// the window or the system asks the process to end.
///
/// The Dart Tooling Daemon does not end when its parent does, so the shell
/// has to end it. A shell that is killed cannot, and leaves it running.
void _closeProjectOnExit(WorkbenchController controller) {
  AppLifecycleListener(
    onExitRequested: () async {
      await controller.closeProject();
      return AppExitResponse.exit;
    },
  );
  for (final signal in [ProcessSignal.sigterm, ProcessSignal.sigint]) {
    signal.watch().listen((_) async {
      await controller.closeProject();
      exit(0);
    });
  }
}

/// Returns the language of the interface: the one of the system when Studio
/// has its text, English otherwise.
Locale _interfaceLocale() {
  final preferred = PlatformDispatcher.instance.locale;
  return StudioLocalizations.supportedLocales.firstWhere(
    (locale) => locale.languageCode == preferred.languageCode,
    orElse: () => StudioLocalizations.supportedLocales.first,
  );
}
