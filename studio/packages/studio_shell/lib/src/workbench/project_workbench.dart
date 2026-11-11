import 'package:devtools_app/devtools_app.dart';
import 'package:devtools_app_shared/ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:studio_core/studio_core.dart';

import '../inherited/inherited_dev_tools.dart';
import '../l10n/studio_localizations.dart';
import 'output_pane.dart';
import 'run_toolbar.dart';
import 'workbench_controller.dart';

/// The workbench of an open project: the widget tree of the running app,
/// the properties of the selected widget and the output of the run.
final class ProjectWorkbench extends StatelessWidget {
  /// Creates the workbench of [project].
  const ProjectWorkbench({
    super.key,
    required this.controller,
    required this.devTools,
    required this.project,
    required this.texts,
  });

  /// Share of the height taken by the tree and the properties; the output
  /// takes the rest.
  static const _editingFraction = 0.75;

  /// Share of the width taken by the widget tree; the properties take the
  /// rest.
  static const _treeFraction = 0.65;

  /// Controller that runs the app.
  final WorkbenchController controller;

  /// Adapter that provides the inherited panels.
  final InheritedDevTools devTools;

  /// The open project.
  final FlutterProject project;

  /// Text of the interface in the language of the user.
  final StudioLocalizations texts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RunToolbar(controller: controller, project: project, texts: texts),
        const SizedBox(height: denseSpacing),
        Expanded(
          child: SplitPane(
            axis: Axis.vertical,
            initialFractions: const [_editingFraction, 1 - _editingFraction],
            children: [
              SplitPane(
                axis: Axis.horizontal,
                initialFractions: const [_treeFraction, 1 - _treeFraction],
                children: [_widgetTree(), _properties()],
              ),
              OutputPane(title: texts.outputTitle, output: controller.output),
            ],
          ),
        ),
      ],
    );
  }

  Widget _widgetTree() => ValueListenableBuilder(
    valueListenable: devTools.inspector,
    builder: (context, inspector, _) => inspector == null
        ? RoundedOutlinedBorder(
            child: Center(child: Text(texts.widgetTreePlaceholder)),
          )
        : InspectorScreenBody(controller: inspector),
  );

  Widget _properties() => RoundedOutlinedBorder(
    clip: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AreaPaneHeader(
          title: Text(texts.propertiesTitle),
          roundedTopBorder: false,
        ),
        Expanded(child: PropertyEditorPanel(devTools.daemonManager)),
      ],
    ),
  );
}
