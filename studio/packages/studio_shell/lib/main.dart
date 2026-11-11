import 'package:devtools_app/devtools_app.dart';
import 'package:devtools_app/initialization.dart';
import 'package:devtools_app_shared/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/inherited_assets/inherited_font_registry.dart';
import 'src/studio_widgets_binding.dart';

/// Starts the shell on top of the inherited DevTools application.
void main() {
  BindingBase.debugZoneErrorsAreFatal = true;
  setGlobal(
    DevToolsEnvironmentParameters,
    ExternalDevToolsEnvironmentParameters(),
  );
  runDevTools(
    ensureBindingInitialized: StudioWidgetsBinding.ensureInitialized,
    onDevToolsInitialized: () => InheritedFontRegistry(
      rootBundle,
      packageName: inheritedPackageName,
    ).registerAliases(),
  );
}
