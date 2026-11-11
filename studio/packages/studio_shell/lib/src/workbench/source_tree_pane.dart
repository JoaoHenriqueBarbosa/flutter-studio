import 'package:devtools_app/devtools_app.dart';
import 'package:devtools_app_shared/ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as path;
import 'package:studio_core/studio_core.dart' show ProjectSession;
import 'package:studio_protocol/studio_protocol.dart' show SourceNode;

import '../l10n/studio_localizations.dart';
import 'source_tree_controller.dart';

/// The pane with the tree of widgets derived from the source of a file,
/// which exists whether the app is running or not (FR-INS-002).
final class SourceTreePane extends StatefulWidget {
  /// Creates the pane for the project of [session].
  const SourceTreePane({super.key, required this.session, required this.texts});

  /// The session of the open project.
  final ProjectSession session;

  /// Text of the interface in the language of the user.
  final StudioLocalizations texts;

  @override
  State<SourceTreePane> createState() => _SourceTreePaneState();
}

final class _SourceTreePaneState extends State<SourceTreePane> {
  /// The file whose tree is shown before anything is selected.
  static const _entryPointParts = ['lib', 'main.dart'];

  late SourceTreeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _createController();
  }

  @override
  void didUpdateWidget(SourceTreePane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      _controller.dispose();
      _controller = _createController();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  SourceTreeController _createController() {
    final session = widget.session;
    return SourceTreeController(
      session.service,
      session.selection.selection,
      session.documents.changes,
      initialFilePath: path.joinAll([
        session.project.rootPath,
        ..._entryPointParts,
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RoundedOutlinedBorder(
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AreaPaneHeader(
            title: Text(widget.texts.structureTitle),
            roundedTopBorder: false,
          ),
          Expanded(
            child: MultiValueListenableBuilder(
              listenables: [_controller.roots, _controller.selection],
              builder: (context, _, _) {
                final rows = [
                  for (final root in _controller.roots.value)
                    ..._rowsOf(root, depth: 0),
                ];
                return rows.isEmpty
                    ? Center(child: Text(widget.texts.structurePlaceholder))
                    : ListView(children: rows);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _rowsOf(SourceNode node, {required int depth}) => [
    _SourceTreeRow(
      node: node,
      depth: depth,
      isSelected: _controller.isSelected(node),
      onTap: () => _controller.select(node),
    ),
    for (final child in node.children) ..._rowsOf(child, depth: depth + 1),
  ];
}

/// One widget of the source tree, indented by its depth.
final class _SourceTreeRow extends StatelessWidget {
  const _SourceTreeRow({
    required this.node,
    required this.depth,
    required this.isSelected,
    required this.onTap,
  });

  final SourceNode node;

  final int depth;

  final bool isSelected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final owner = node.owner;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isSelected ? theme.colorScheme.selectedRowBackgroundColor : null,
        padding: EdgeInsets.only(
          left: denseSpacing + depth * defaultSpacing,
          right: denseSpacing,
          top: densePadding,
          bottom: densePadding,
        ),
        child: Row(
          children: [
            Text(node.className, style: theme.regularTextStyle),
            if (owner != null) ...[
              const SizedBox(width: denseSpacing),
              Expanded(
                child: Text(
                  owner,
                  style: theme.subtleTextStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
