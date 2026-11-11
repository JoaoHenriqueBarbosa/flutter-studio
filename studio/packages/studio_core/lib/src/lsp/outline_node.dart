import '../document/text_edit.dart';

/// One node of the Flutter Outline that the analysis server computes from
/// the source of a file.
///
/// A node is either the creation of a widget, when [className] is set, or a
/// declaration that contains such creations, when [elementName] is set.
final class OutlineNode {
  /// Creates a node that spans [range] and contains [children].
  const OutlineNode({
    required this.range,
    required this.children,
    this.className,
    this.elementName,
  });

  /// The source of the node, from its first token.
  final DocumentRange range;

  /// The nodes inside this one, in source order.
  final List<OutlineNode> children;

  /// Class of the widget that the node creates, or `null` when the node is
  /// a declaration.
  final String? className;

  /// Name of the declaration, such as a class or a method, or `null` when
  /// the node creates a widget.
  final String? elementName;
}
