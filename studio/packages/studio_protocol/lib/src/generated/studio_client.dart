// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';
import 'edit_result.dart';
import 'expression.dart';
import 'move_direction.dart';
import 'property.dart';
import 'source_node.dart';
import 'structure_options.dart';
import 'studio_api.dart';
import 'studio_method.dart';
import 'swap_partner.dart';
import 'version_info.dart';
import 'widget_ref.dart';
import 'widget_spec.dart';

/// Sends one call of the `Studio` service and completes with its result,
/// both in JSON form.
typedef StudioCall =
    Future<Object?> Function(StudioMethod method, Map<String, Object?> params);

/// Client of the `Studio` service over any transport.
final class StudioClient implements StudioApi {
  /// Creates a client that sends each call through [_call].
  const StudioClient(this._call);

  final StudioCall _call;

  @override
  Future<VersionInfo> getVersion() async {
    final result = await _call(StudioMethod.getVersion, {});
    return VersionInfo.fromJson(result);
  }

  @override
  Future<List<SourceNode>> getSourceTree({required String uri}) async {
    final result = await _call(StudioMethod.getSourceTree, {'uri': uri});
    return [
      for (final item in asJson<List<Object?>>(result))
        SourceNode.fromJson(item),
    ];
  }

  @override
  Future<WidgetRef?> getSelection() async {
    final result = await _call(StudioMethod.getSelection, {});
    return switch (result) {
      null => null,
      final value => WidgetRef.fromJson(value),
    };
  }

  @override
  Future<WidgetRef> select({required WidgetRef target}) async {
    final result = await _call(StudioMethod.select, {
      'target': target.toJson(),
    });
    return WidgetRef.fromJson(result);
  }

  @override
  Future<List<Property>> getProperties({required WidgetRef target}) async {
    final result = await _call(StudioMethod.getProperties, {
      'target': target.toJson(),
    });
    return [
      for (final item in asJson<List<Object?>>(result)) Property.fromJson(item),
    ];
  }

  @override
  Future<EditResult> setProperty({
    required WidgetRef target,
    required String name,
    required Expression? value,
  }) async {
    final result = await _call(StudioMethod.setProperty, {
      'target': target.toJson(),
      'name': name,
      'value': switch (value) {
        null => null,
        final value => value.toJson(),
      },
    });
    return EditResult.fromJson(result);
  }

  @override
  Future<StructureOptions> getStructureOptions({
    required WidgetRef target,
  }) async {
    final result = await _call(StudioMethod.getStructureOptions, {
      'target': target.toJson(),
    });
    return StructureOptions.fromJson(result);
  }

  @override
  Future<EditResult> wrapWidget({
    required WidgetRef target,
    required WidgetSpec wrapper,
  }) async {
    final result = await _call(StudioMethod.wrapWidget, {
      'target': target.toJson(),
      'wrapper': wrapper.toJson(),
    });
    return EditResult.fromJson(result);
  }

  @override
  Future<EditResult> removeWidget({
    required WidgetRef target,
    required bool keepChildren,
  }) async {
    final result = await _call(StudioMethod.removeWidget, {
      'target': target.toJson(),
      'keepChildren': keepChildren,
    });
    return EditResult.fromJson(result);
  }

  @override
  Future<EditResult> reorderWidget({
    required WidgetRef target,
    required MoveDirection direction,
  }) async {
    final result = await _call(StudioMethod.reorderWidget, {
      'target': target.toJson(),
      'direction': direction.toJson(),
    });
    return EditResult.fromJson(result);
  }

  @override
  Future<EditResult> swapWidget({
    required WidgetRef target,
    required SwapPartner partner,
  }) async {
    final result = await _call(StudioMethod.swapWidget, {
      'target': target.toJson(),
      'partner': partner.toJson(),
    });
    return EditResult.fromJson(result);
  }

  @override
  Future<EditResult> undo() async {
    final result = await _call(StudioMethod.undo, {});
    return EditResult.fromJson(result);
  }

  @override
  Future<EditResult> redo() async {
    final result = await _call(StudioMethod.redo, {});
    return EditResult.fromJson(result);
  }
}
