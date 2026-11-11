import '../document/text_document.dart';
import '../document/text_edit.dart';
import '../lsp/outline_node.dart';
import 'source_node.dart';

/// Builds the tree of widgets of a file from its Flutter Outline.
///
/// The outline starts a creation at its first token, which may be `const`
/// or `new`. The framework records the creation at the name of the class,
/// so the builder reads the text to find where the name starts.
final class SourceTreeBuilder {
  /// Creates a builder that reads positions in [_document].
  const SourceTreeBuilder(this._document);

  static final _creationKeyword = RegExp(r'(const|new)\s+');

  final TextDocument _document;

  /// Returns the widgets under [root] that no other widget contains.
  ///
  /// [root] is the node of the whole file, which names no declaration.
  List<SourceNode> build(OutlineNode root) => [
    for (final child in root.children) ..._rootsUnder(child, const []),
  ];

  List<SourceNode> _rootsUnder(OutlineNode node, List<String> ownerNames) {
    final className = node.className;
    if (className != null) {
      return [
        _widget(
          node,
          className,
          owner: ownerNames.isEmpty ? null : ownerNames.join('.'),
        ),
      ];
    }
    final names = [...ownerNames, ?node.elementName];
    return [for (final child in node.children) ..._rootsUnder(child, names)];
  }

  SourceNode _widget(OutlineNode node, String className, {String? owner}) =>
      SourceNode(
        className: className,
        position: _creationPosition(node.range.start),
        owner: owner,
        children: [for (final child in node.children) ..._widgetsUnder(child)],
      );

  /// Returns the widgets under [node] that are nearest to it. A declaration
  /// between two widgets, such as a local function, is skipped.
  List<SourceNode> _widgetsUnder(OutlineNode node) {
    final className = node.className;
    return className != null
        ? [_widget(node, className)]
        : [for (final child in node.children) ..._widgetsUnder(child)];
  }

  DocumentPosition _creationPosition(DocumentPosition start) {
    final offset = _document.offsetAt(start);
    final keyword = _creationKeyword.matchAsPrefix(_document.text, offset);
    return keyword == null ? start : _document.positionAt(keyword.end);
  }
}
