// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import 'edit_result.dart';
import 'expression.dart';
import 'move_direction.dart';
import 'property.dart';
import 'runtime_node.dart';
import 'source_node.dart';
import 'structure_options.dart';
import 'swap_partner.dart';
import 'version_info.dart';
import 'widget_ref.dart';
import 'widget_spec.dart';

/// Operations of Studio: reading, selecting and editing the widgets of the open
/// project.
///
/// A method fails with a `StudioFault` that carries one of the errors it
/// declares.
abstract interface class StudioApi {
  /// Returns the version of this contract.
  Future<VersionInfo> getVersion();

  /// Returns the widgets that the source of a file creates.
  ///
  /// The result has the widgets that no other widget contains, in source order,
  /// each with the widgets created inside its arguments. Branches that are not
  /// rendered are included.
  ///
  /// The parameter [uri]: the file URI of a Dart file of the project.
  ///
  /// Errors: `NotInProject`, `UnsupportedTarget`, `ToolchainUnavailable`.
  Future<List<SourceNode>> getSourceTree({required String uri});

  /// Returns the widgets of the project in the running app, each with its
  /// creation location.
  ///
  /// The tree comes from the frame on the canvas. Widgets created outside the
  /// project are left out, and their descendants created in the project take
  /// their place.
  ///
  /// Errors: `NoSession`.
  Future<List<RuntimeNode>> getRuntimeTree();

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

  /// Tells which structural edits a widget accepts.
  ///
  /// The parameter [target]: the widget that would be edited.
  ///
  /// Errors: `StaleDocument`, `NotInProject`, `ToolchainUnavailable`.
  Future<StructureOptions> getStructureOptions({required WidgetRef target});

  /// Wraps a widget with a new widget, which takes it as child.
  ///
  /// The wrapper has to be one of the wrappers that getStructureOptions lists
  /// for the widget.
  ///
  /// The parameter [target]: the widget to wrap.
  ///
  /// The parameter [wrapper]: the widget to create around the target.
  ///
  /// Errors: `StaleDocument`, `NotInProject`, `UnsupportedTarget`,
  /// `ToolchainUnavailable`.
  Future<EditResult> wrapWidget({
    required WidgetRef target,
    required WidgetSpec wrapper,
  });

  /// Removes a widget from the code.
  ///
  /// With keepChildren set to true the children of the widget take its place.
  /// Removing the children as well is not supported in this version.
  ///
  /// The parameter [target]: the widget to remove.
  ///
  /// The parameter [keepChildren]: whether the children of the widget stay in
  /// the code.
  ///
  /// Errors: `StaleDocument`, `NotInProject`, `UnsupportedTarget`,
  /// `ToolchainUnavailable`.
  Future<EditResult> removeWidget({
    required WidgetRef target,
    required bool keepChildren,
  });

  /// Moves a widget one place among its siblings.
  ///
  /// The parameter [target]: the widget to move.
  ///
  /// The parameter [direction]: where the widget goes in the list of its
  /// siblings.
  ///
  /// Errors: `StaleDocument`, `NotInProject`, `UnsupportedTarget`,
  /// `ToolchainUnavailable`.
  Future<EditResult> reorderWidget({
    required WidgetRef target,
    required MoveDirection direction,
  });

  /// Swaps a widget with its parent or with its child.
  ///
  /// The parameter [target]: the widget to swap.
  ///
  /// The parameter [partner]: the widget that changes places with the target.
  ///
  /// Errors: `StaleDocument`, `NotInProject`, `UnsupportedTarget`,
  /// `ToolchainUnavailable`.
  Future<EditResult> swapWidget({
    required WidgetRef target,
    required SwapPartner partner,
  });

  /// Extracts a widget and its subtree to a new widget class in the same file.
  ///
  /// What the subtree uses from its surroundings becomes a parameter of the new
  /// class.
  ///
  /// The parameter [target]: the widget at the top of the subtree to extract.
  ///
  /// The parameter [name]: name of the new class, in UpperCamelCase.
  ///
  /// Errors: `StaleDocument`, `NotInProject`, `UnsupportedTarget`,
  /// `ToolchainUnavailable`.
  Future<EditResult> extractWidget({
    required WidgetRef target,
    required String name,
  });

  /// Converts a StatelessWidget of the project into a StatefulWidget with its
  /// State class.
  ///
  /// The parameter [declaration]: a position inside the name of the class, in
  /// its declaration, with the version of the document.
  ///
  /// Errors: `StaleDocument`, `NotInProject`, `UnsupportedTarget`,
  /// `ToolchainUnavailable`.
  Future<EditResult> convertToStatefulWidget({required WidgetRef declaration});

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
