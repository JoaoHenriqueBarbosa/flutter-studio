import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// Shows the output of the build and of the app (FR-RUN-003).
final class OutputPane extends StatelessWidget {
  /// Creates the pane titled [title] that follows [output].
  const OutputPane({super.key, required this.title, required this.output});

  /// Title of the pane.
  final String title;

  /// The text to show, which grows while the app runs.
  final ValueListenable<String> output;

  @override
  Widget build(BuildContext context) {
    return RoundedOutlinedBorder(
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AreaPaneHeader(title: Text(title), roundedTopBorder: false),
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              padding: const EdgeInsets.all(denseSpacing),
              child: ValueListenableBuilder(
                valueListenable: output,
                builder: (context, text, _) => SelectableText(
                  text,
                  style: Theme.of(context).fixedFontStyle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
