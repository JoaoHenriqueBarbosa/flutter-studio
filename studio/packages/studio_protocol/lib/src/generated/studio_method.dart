// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

/// The methods of the `Studio` service.
///
/// The name of each value is its name on the wire.
enum StudioMethod {
  /// Returns the version of this contract.
  getVersion,

  /// Returns the selected widget, or null when nothing is selected.
  getSelection,

  /// Selects a widget in every view and returns the widget that ended up
  /// selected.
  select,

  /// Lists the parameters of the constructor that creates a widget.
  getProperties,

  /// Changes one argument of the constructor that creates a widget.
  setProperty,

  /// Undoes the last edit and restores the exact previous bytes of its files.
  undo,

  /// Applies again the edit that the last undo removed.
  redo,
}
