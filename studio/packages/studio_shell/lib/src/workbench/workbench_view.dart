import 'package:devtools_app_shared/ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:studio_core/studio_core.dart';

import '../inherited/inherited_dev_tools.dart';
import '../l10n/studio_localizations.dart';
import 'open_project_prompt.dart';
import 'project_workbench.dart';
import 'workbench_controller.dart';
import 'workbench_state.dart';

/// The body of the Studio screen, for whatever the workbench has open.
final class WorkbenchView extends StatelessWidget {
  /// Creates the view of [controller].
  const WorkbenchView({
    super.key,
    required this.controller,
    required this.devTools,
    required this.texts,
  });

  /// Controller that the view observes and calls.
  final WorkbenchController controller;

  /// Adapter that provides the inherited panels.
  final InheritedDevTools devTools;

  /// Text of the interface in the language of the user.
  final StudioLocalizations texts;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.state,
      builder: (context, state, _) => switch (state) {
        WorkbenchEmpty() => OpenProjectPrompt(
          controller: controller,
          texts: texts,
        ),
        WorkbenchOpening(:final projectPath) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: defaultSpacing),
              Text(texts.openingProject(projectPath)),
            ],
          ),
        ),
        WorkbenchFailed(:final failure) => OpenProjectPrompt(
          controller: controller,
          texts: texts,
          errorMessage: _describe(failure),
        ),
        WorkbenchReady(:final session) => ProjectWorkbench(
          controller: controller,
          devTools: devTools,
          project: session.project,
          texts: texts,
        ),
      },
    );
  }

  String _describe(ProjectOpenFailure failure) => switch (failure) {
    NotAFlutterProject(:final projectPath) => texts.notAFlutterProject(
      projectPath,
    ),
    SdkNotFound(:final searchedPath?) => texts.sdkNotFoundAt(searchedPath),
    SdkNotFound() => texts.sdkNotFound,
    SdkOutsideWindow(:final found, :final window) => texts.sdkOutsideWindow(
      '$found',
      '$window',
    ),
  };
}
