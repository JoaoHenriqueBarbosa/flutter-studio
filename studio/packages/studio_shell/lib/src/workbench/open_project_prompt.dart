import 'package:devtools_app_shared/ui.dart';
import 'package:file_selector/file_selector.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/studio_localizations.dart';
import 'workbench_controller.dart';

/// Invites the user to choose the directory of a project.
final class OpenProjectPrompt extends StatelessWidget {
  /// Creates the prompt. [errorMessage] explains why the last attempt to
  /// open a project failed, when there was one.
  const OpenProjectPrompt({
    super.key,
    required this.controller,
    required this.texts,
    this.errorMessage,
  });

  /// Controller that opens the chosen directory.
  final WorkbenchController controller;

  /// Text of the interface in the language of the user.
  final StudioLocalizations texts;

  /// Why the last attempt failed, or `null` when none failed.
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorMessage = this.errorMessage;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (errorMessage != null) ...[
            Text(
              errorMessage,
              style: theme.regularTextStyle.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: defaultSpacing),
          ],
          Text(texts.openProjectHint),
          const SizedBox(height: defaultSpacing),
          DevToolsButton(
            icon: Icons.folder_open,
            label: texts.openProjectAction,
            elevated: true,
            onPressed: _chooseProject,
          ),
        ],
      ),
    );
  }

  Future<void> _chooseProject() async {
    final projectPath = await getDirectoryPath();
    if (projectPath != null) await controller.openProject(projectPath);
  }
}
