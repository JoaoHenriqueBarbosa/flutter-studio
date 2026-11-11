import 'package:devtools_app/devtools_app.dart';
import 'package:devtools_app_shared/ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:studio_core/studio_core.dart';

import '../l10n/studio_localizations.dart';
import 'app_run_status.dart';
import 'workbench_controller.dart';

/// The bar with the open project and the actions that run its app.
final class RunToolbar extends StatelessWidget {
  /// Creates the toolbar of [project].
  const RunToolbar({
    super.key,
    required this.controller,
    required this.project,
    required this.texts,
  });

  /// Controller that runs the app.
  final WorkbenchController controller;

  /// The open project.
  final FlutterProject project;

  /// Text of the interface in the language of the user.
  final StudioLocalizations texts;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          texts.projectSummary(project.name, '${project.sdk.version}'),
          style: Theme.of(context).boldTextStyle,
        ),
        const Spacer(),
        ValueListenableBuilder(
          valueListenable: controller.runStatus,
          builder: (context, status, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: switch (status) {
              AppRunStatus.stopped => [
                DevToolsButton(
                  icon: Icons.play_arrow,
                  label: texts.runAction,
                  onPressed: () => controller.runApp(
                    DevToolsRouterDelegate.of(context),
                    target: const RunTarget.designHost(),
                  ),
                ),
                const SizedBox(width: denseSpacing),
                DevToolsButton(
                  icon: Icons.desktop_windows_outlined,
                  tooltip: texts.runInWindowAction,
                  onPressed: () => controller.runApp(
                    DevToolsRouterDelegate.of(context),
                    target: RunTarget.desktop(),
                  ),
                ),
              ],
              AppRunStatus.starting => [
                Text(texts.startingApp),
                const SizedBox(width: denseSpacing),
                _stopButton(context),
              ],
              AppRunStatus.running => [
                DevToolsButton(
                  icon: Icons.restart_alt,
                  label: texts.hotRestartAction,
                  onPressed: controller.restartApp,
                ),
                const SizedBox(width: denseSpacing),
                _stopButton(context),
              ],
            },
          ),
        ),
      ],
    );
  }

  Widget _stopButton(BuildContext context) => DevToolsButton(
    icon: Icons.stop,
    label: texts.stopAction,
    onPressed: () => controller.stopApp(DevToolsRouterDelegate.of(context)),
  );
}
