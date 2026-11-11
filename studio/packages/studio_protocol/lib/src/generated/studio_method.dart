// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

/// The methods of the `Studio` service.
///
/// The name of each value is its name on the wire.
enum StudioMethod {
  /// Returns the version of this contract.
  getVersion,

  /// Returns the widgets that the source of a file creates.
  getSourceTree,

  /// Returns the widgets of the project in the running app, each with its
  /// creation location.
  getRuntimeTree,

  /// Returns the selected widget, or null when nothing is selected.
  getSelection,

  /// Selects a widget in every view and returns the widget that ended up
  /// selected.
  select,

  /// Lists the parameters of the constructor that creates a widget.
  getProperties,

  /// Changes one argument of the constructor that creates a widget.
  setProperty,

  /// Tells which structural edits a widget accepts.
  getStructureOptions,

  /// Wraps a widget with a new widget, which takes it as child.
  wrapWidget,

  /// Removes a widget from the code.
  removeWidget,

  /// Moves a widget one place among its siblings.
  reorderWidget,

  /// Swaps a widget with its parent or with its child.
  swapWidget,

  /// Undoes the last edit and restores the exact previous bytes of its files.
  undo,

  /// Applies again the edit that the last undo removed.
  redo,
}
