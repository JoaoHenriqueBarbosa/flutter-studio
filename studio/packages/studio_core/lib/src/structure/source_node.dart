import '../document/text_edit.dart';

/// A widget in the tree derived from the source of a file (FR-INS-002).
///
/// The tree has every widget that the code creates, including the ones in
/// branches that are not rendered.
final class SourceNode {
  /// Creates the node of the widget [className] created at [position].
  const SourceNode({
    required this.className,
    required this.position,
    required this.children,
    this.owner,
  });

  /// Class of the widget.
  final String className;

  /// Position of the constructor call that creates the widget, after any
  /// `const` or `new`. It is the creation location that the framework
  /// records for the widget at run time (ADR-0005).
  final DocumentPosition position;

  /// The widgets created inside the arguments of this one, in source order.
  final List<SourceNode> children;

  /// Qualified name of the declaration that creates the widget, such as
  /// `MyHomePage.build`. Set only in a widget that no other widget
  /// contains.
  final String? owner;
}
