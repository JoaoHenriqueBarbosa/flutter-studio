/// The kind of an assist of the analysis server that edits the structure
/// of the widget tree, the second level of editing (ADR-0006).
///
/// [kind] is the kind of the code action, as the server names it.
extension type const WidgetAssist(String kind) {
  /// The assist that wraps a widget with the widget class [className], such
  /// as `Center`.
  WidgetAssist.wrapWith(String className)
    : this(
        '$_wrapPrefix${className.substring(0, 1).toLowerCase()}'
        '${className.substring(1)}',
      );

  /// Prefix of the kinds of every Flutter assist.
  static const flutterPrefix = 'refactor.flutter';

  /// The assist that removes a widget and keeps its children.
  static const remove = WidgetAssist('$flutterPrefix.removeWidget');

  /// The assist that moves a widget up among its siblings.
  static const moveUp = WidgetAssist('$flutterPrefix.move.up');

  /// The assist that moves a widget down among its siblings.
  static const moveDown = WidgetAssist('$flutterPrefix.move.down');

  /// The assist that swaps a widget with its parent.
  static const swapWithParent = WidgetAssist('$flutterPrefix.swap.withParent');

  /// The assist that swaps a widget with its child.
  static const swapWithChild = WidgetAssist('$flutterPrefix.swap.withChild');

  static const _wrapPrefix = '$flutterPrefix.wrap.';

  /// Suffix of the wrap that asks the user for the widget. It names no
  /// class, so it is not offered as a wrapper.
  static const _genericWrap = 'generic';

  /// The widget class that this assist wraps with, or `null` when it is
  /// not a wrap with a named class.
  String? get wrapperClassName {
    if (!kind.startsWith(_wrapPrefix)) return null;
    final suffix = kind.substring(_wrapPrefix.length);
    if (suffix.isEmpty || suffix == _genericWrap) return null;
    return '${suffix.substring(0, 1).toUpperCase()}${suffix.substring(1)}';
  }
}
