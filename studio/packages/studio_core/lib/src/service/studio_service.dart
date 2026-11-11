import 'dart:io';

import 'package:studio_protocol/studio_protocol.dart';

import '../document/applied_edit.dart';
import '../document/document_store.dart';
import '../document/edit_failure.dart';
import '../document/source_location.dart';
import '../document/text_edit.dart' as document;
import '../edit/argument_literal.dart';
import '../edit/edit_outcome.dart';
import '../edit/edit_pipeline.dart';
import '../edit/widget_reader.dart';
import '../lsp/editable_argument.dart';
import '../lsp/widget_assist.dart';
import '../selection/selection_controller.dart';
import '../selection/widget_location.dart';
import '../structure/source_node.dart' as structure;
import '../structure/source_tree.dart';

/// The `Studio` service: the single entry for every operation (ADR-0012).
///
/// A Facade over the documents, the selection and the edit pipeline. It
/// converts between the types of the contract and the ones of the core, and
/// turns every [EditFailure] into the [StudioFault] that the contract names.
final class StudioService implements StudioApi {
  /// Creates the service over the parts of an open project.
  const StudioService(
    this._documents,
    this._selection,
    this._pipeline,
    this._reader,
  );

  final DocumentStore _documents;

  final SelectionController _selection;

  final EditPipeline _pipeline;

  final WidgetReader _reader;

  /// Index of the parent of a scene element that has no ancestor.
  static const _noParent = -1;

  /// The library that exports every widget the analysis server wraps with.
  static const _widgetsLibrary = 'package:flutter/widgets.dart';

  @override
  Future<VersionInfo> getVersion() async =>
      const VersionInfo(version: StudioContract.version);

  @override
  Future<List<SourceNode>> getSourceTree({required String uri}) =>
      _guarded(() async {
        final filePath = _filePathOf(uri);
        if (!_documents.contains(filePath)) throw EditOutsideProject(filePath);
        final tree = await _reader.sourceTree(filePath);
        return [for (final root in tree.roots) _nodeOf(root, tree)];
      });

  @override
  Future<List<RuntimeNode>> getRuntimeTree() async {
    final scene = _reader.runningScene();
    if (scene == null) {
      throw const StudioFault(
        StudioErrorCode.noSession,
        data: 'No app with the design agent is running.',
      );
    }
    return _runtimeNodesUnder(scene, _noParent);
  }

  @override
  Future<WidgetRef?> getSelection() async =>
      switch (_selection.selection.value) {
        null => null,
        final selected => _referenceOf(selected),
      };

  @override
  Future<WidgetRef> select({required WidgetRef target}) => _guarded(
    () async => _referenceOf(_selection.select(_locationOf(target))),
  );

  @override
  Future<List<Property>> getProperties({required WidgetRef target}) =>
      _guarded(() async {
        final arguments = await _reader.arguments(_locationOf(target));
        return arguments.map(_propertyOf).toList();
      });

  @override
  Future<EditResult> setProperty({
    required WidgetRef target,
    required String name,
    required Expression? value,
  }) => _guarded(
    () async => _resultOf(
      await _pipeline.setArgument(
        _locationOf(target),
        documentVersion: target.documentVersion,
        name: name,
        source: value?.source,
      ),
    ),
  );

  @override
  Future<StructureOptions> getStructureOptions({required WidgetRef target}) =>
      _guarded(() async {
        final assists = await _reader.assists(_locationOf(target));
        final offered = {for (final each in assists) each.assist};
        return StructureOptions(
          wrappers: [
            for (final assist in offered)
              if (assist.wrapperClassName case final className?)
                WidgetSpec(libraryUri: _widgetsLibrary, className: className),
          ],
          canRemove: offered.contains(WidgetAssist.remove),
          canMoveUp: offered.contains(WidgetAssist.moveUp),
          canMoveDown: offered.contains(WidgetAssist.moveDown),
          canSwapWithParent: offered.contains(WidgetAssist.swapWithParent),
          canSwapWithChild: offered.contains(WidgetAssist.swapWithChild),
        );
      });

  @override
  Future<EditResult> wrapWidget({
    required WidgetRef target,
    required WidgetSpec wrapper,
  }) {
    if (wrapper.libraryUri != _widgetsLibrary) {
      throw const StudioFault(
        StudioErrorCode.unsupportedTarget,
        data: 'Only the wrappers of getStructureOptions are supported.',
      );
    }
    return _assist(target, WidgetAssist.wrapWith(wrapper.className));
  }

  @override
  Future<EditResult> removeWidget({
    required WidgetRef target,
    required bool keepChildren,
  }) {
    if (!keepChildren) {
      throw const StudioFault(
        StudioErrorCode.unsupportedTarget,
        data: 'Removing a widget with its children is not built yet.',
      );
    }
    return _assist(target, WidgetAssist.remove);
  }

  @override
  Future<EditResult> reorderWidget({
    required WidgetRef target,
    required MoveDirection direction,
  }) => _assist(target, switch (direction) {
    MoveDirection.up => WidgetAssist.moveUp,
    MoveDirection.down => WidgetAssist.moveDown,
  });

  @override
  Future<EditResult> swapWidget({
    required WidgetRef target,
    required SwapPartner partner,
  }) => _assist(target, switch (partner) {
    SwapPartner.parent => WidgetAssist.swapWithParent,
    SwapPartner.child => WidgetAssist.swapWithChild,
  });

  @override
  Future<EditResult> extractWidget({
    required WidgetRef target,
    required String name,
  }) => _guarded(
    () async => _resultOf(
      await _pipeline.extractWidget(
        _locationOf(target),
        documentVersion: target.documentVersion,
        name: name,
      ),
    ),
  );

  @override
  Future<EditResult> convertToStatefulWidget({
    required WidgetRef declaration,
  }) => _assist(declaration, WidgetAssist.toStatefulWidget);

  @override
  Future<EditResult> undo() =>
      _guarded(() async => _resultOf(await _pipeline.undo()));

  @override
  Future<EditResult> redo() =>
      _guarded(() async => _resultOf(await _pipeline.redo()));

  /// Applies [assist] to [target] through the pipeline.
  Future<EditResult> _assist(WidgetRef target, WidgetAssist assist) => _guarded(
    () async => _resultOf(
      await _pipeline.applyAssist(
        _locationOf(target),
        documentVersion: target.documentVersion,
        assist: assist,
      ),
    ),
  );

  /// Runs [operation] and reports its failure as the contract names it.
  Future<T> _guarded<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on EditFailure catch (failure) {
      throw switch (failure) {
        StaleDocument(:final currentVersion) => StudioFault(
          StudioErrorCode.staleDocument,
          data: currentVersion,
        ),
        EditOutsideProject(:final filePath) => StudioFault(
          StudioErrorCode.notInProject,
          data: '${Uri.file(filePath)}',
        ),
        UnsupportedEdit(:final reason) => StudioFault(
          StudioErrorCode.unsupportedTarget,
          data: reason,
        ),
        InvalidEdit(:final message) => StudioFault(
          StudioErrorCode.unsupportedTarget,
          data: message,
        ),
        ToolUnavailable(:final toolName) => StudioFault(
          StudioErrorCode.toolchainUnavailable,
          data: toolName,
        ),
      };
    } on FileSystemException catch (exception) {
      throw StudioFault(
        StudioErrorCode.unsupportedTarget,
        data: exception.message,
      );
    }
  }

  /// Returns where [reference] points, after checking that its document is
  /// in the project and at the version of the reference.
  SourceLocation _locationOf(WidgetRef reference) {
    final filePath = _filePathOf(reference.uri);
    _documents.documentAt(filePath, version: reference.documentVersion);
    return (
      filePath: filePath,
      position: (
        line: reference.position.line,
        character: reference.position.character,
      ),
    );
  }

  /// Returns the elements of [scene] whose parent is the element at
  /// [parentIndex], each with its own descendants.
  List<RuntimeNode> _runtimeNodesUnder(Scene scene, int parentIndex) => [
    for (final (index, element) in scene.elements.indexed)
      if (element.parentIndex == parentIndex)
        RuntimeNode(
          className: element.className,
          ref: WidgetRef(
            uri: element.uri,
            position: element.position,
            documentVersion: _documents
                .document(Uri.parse(element.uri).toFilePath())
                .version,
          ),
          bounds: Bounds(
            left: element.left,
            top: element.top,
            width: element.width,
            height: element.height,
          ),
          children: _runtimeNodesUnder(scene, index),
        ),
  ];

  /// Returns the path of the file that [uri] names.
  String _filePathOf(String uri) {
    final parsed = Uri.tryParse(uri);
    if (parsed == null || !parsed.isScheme('file')) {
      throw StudioFault(StudioErrorCode.notInProject, data: uri);
    }
    return parsed.toFilePath();
  }

  SourceNode _nodeOf(structure.SourceNode node, SourceTree tree) => SourceNode(
    ref: _referenceOf((
      filePath: tree.filePath,
      position: node.position,
      documentVersion: tree.documentVersion,
    )),
    className: node.className,
    owner: node.owner,
    children: [for (final child in node.children) _nodeOf(child, tree)],
  );

  WidgetRef _referenceOf(WidgetLocation location) => WidgetRef(
    uri: '${Uri.file(location.filePath)}',
    position: _positionOf(location.position),
    documentVersion: location.documentVersion,
  );

  Position _positionOf(document.DocumentPosition position) =>
      Position(line: position.line, character: position.character);

  Property _propertyOf(EditableArgument argument) {
    final literal = ArgumentLiteral(argument.kind);
    final value = argument.value;
    final defaultValue = argument.defaultValue;
    final source = value == null
        ? argument.displayValue
        : literal.sourceOf(value);
    return Property(
      name: argument.name,
      type: argument.kind,
      expression: argument.hasArgument && source != null
          ? Expression(source: source)
          : null,
      defaultValue: defaultValue == null
          ? null
          : Expression(source: literal.sourceOf(defaultValue)),
      isSet: argument.hasArgument,
      isEditable: argument.isEditable,
      options: argument.options,
      documentation: argument.documentation,
    );
  }

  EditResult _resultOf(EditOutcome outcome) {
    final edit = outcome.edit;
    return EditResult(
      applied: edit != null,
      changes: edit == null ? const [] : _changesOf(edit),
      documentVersions: {
        if (edit != null)
          for (final MapEntry(key: filePath, value: version)
              in edit.versions.entries)
            '${Uri.file(filePath)}': version,
      },
      reload: outcome.isReloadRequested
          ? ReloadKind.hotReload
          : ReloadKind.none,
    );
  }

  List<TextDocumentEdit> _changesOf(AppliedEdit edit) => [
    for (final change in edit.changes)
      TextDocumentEdit(
        uri: '${Uri.file(change.filePath)}',
        edits: [
          for (final textEdit in change.edits)
            TextEdit(
              range: Range(
                start: _positionOf(textEdit.range.start),
                end: _positionOf(textEdit.range.end),
              ),
              newText: textEdit.newText,
            ),
        ],
      ),
  ];
}
