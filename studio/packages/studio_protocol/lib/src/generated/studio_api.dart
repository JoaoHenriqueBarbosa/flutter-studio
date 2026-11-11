// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import 'edit_result.dart';
import 'expression.dart';
import 'property.dart';
import 'version_info.dart';
import 'widget_ref.dart';

/// Operations of Studio: reading, selecting and editing the widgets of the open
/// project.
///
/// A method fails with a `StudioFault` that carries one of the errors it
/// declares.
abstract interface class StudioApi {
  /// Returns the version of this contract.
  Future<VersionInfo> getVersion();

  /// Returns the selected widget, or null when nothing is selected.
  Future<WidgetRef?> getSelection();

  /// Selects a widget in every view and returns the widget that ended up
  /// selected.
  ///
  /// The parameter [target]: the widget to select.
  ///
  /// Errors: `StaleDocument`, `NotInProject`.
  Future<WidgetRef> select({required WidgetRef target});

  /// Lists the parameters of the constructor that creates a widget.
  ///
  /// The parameter [target]: the widget whose constructor is read.
  ///
  /// Errors: `StaleDocument`, `NotInProject`, `ToolchainUnavailable`.
  Future<List<Property>> getProperties({required WidgetRef target});

  /// Changes one argument of the constructor that creates a widget.
  ///
  /// The files are on disk when the call completes. The reload of the running
  /// app is requested but not awaited.
  ///
  /// The parameter [target]: the widget whose argument changes.
  ///
  /// The parameter [name]: name of the constructor parameter.
  ///
  /// The parameter [value]: the new expression of the argument, or null to
  /// remove the argument.
  ///
  /// Errors: `StaleDocument`, `NotInProject`, `UnsupportedTarget`,
  /// `ToolchainUnavailable`.
  Future<EditResult> setProperty({
    required WidgetRef target,
    required String name,
    required Expression? value,
  });

  /// Undoes the last edit and restores the exact previous bytes of its files.
  ///
  /// When there is nothing to undo, the result has applied set to false and no
  /// change.
  Future<EditResult> undo();

  /// Applies again the edit that the last undo removed.
  ///
  /// When there is nothing to redo, the result has applied set to false and no
  /// change.
  Future<EditResult> redo();
}
