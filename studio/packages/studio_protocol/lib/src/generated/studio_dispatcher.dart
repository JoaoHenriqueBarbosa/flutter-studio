// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';
import 'expression.dart';
import 'move_direction.dart';
import 'studio_api.dart';
import 'studio_method.dart';
import 'swap_partner.dart';
import 'widget_ref.dart';
import 'widget_spec.dart';

/// Serves the calls of the `Studio` service: decodes the parameters, runs
/// the method and encodes the result.
final class StudioDispatcher {
  /// Creates a dispatcher that runs the methods of [_api].
  const StudioDispatcher(this._api);

  final StudioApi _api;

  /// Runs [method] with [params] and completes with the result, both in
  /// JSON form.
  ///
  /// Throws a [FormatException] when [params] does not have the form that
  /// the contract gives to the parameters of [method].
  Future<Object?> dispatch(
    StudioMethod method,
    Map<String, Object?> params,
  ) async {
    switch (method) {
      case StudioMethod.getVersion:
        final result = await _api.getVersion();
        return result.toJson();
      case StudioMethod.getSourceTree:
        final result = await _api.getSourceTree(
          uri: asJson<String>(params['uri']),
        );
        return [for (final item in result) item.toJson()];
      case StudioMethod.getRuntimeTree:
        final result = await _api.getRuntimeTree();
        return [for (final item in result) item.toJson()];
      case StudioMethod.getSelection:
        final result = await _api.getSelection();
        return switch (result) {
          null => null,
          final value => value.toJson(),
        };
      case StudioMethod.select:
        final result = await _api.select(
          target: WidgetRef.fromJson(params['target']),
        );
        return result.toJson();
      case StudioMethod.getProperties:
        final result = await _api.getProperties(
          target: WidgetRef.fromJson(params['target']),
        );
        return [for (final item in result) item.toJson()];
      case StudioMethod.setProperty:
        final result = await _api.setProperty(
          target: WidgetRef.fromJson(params['target']),
          name: asJson<String>(params['name']),
          value: switch (params['value']) {
            null => null,
            final value => Expression.fromJson(value),
          },
        );
        return result.toJson();
      case StudioMethod.getStructureOptions:
        final result = await _api.getStructureOptions(
          target: WidgetRef.fromJson(params['target']),
        );
        return result.toJson();
      case StudioMethod.wrapWidget:
        final result = await _api.wrapWidget(
          target: WidgetRef.fromJson(params['target']),
          wrapper: WidgetSpec.fromJson(params['wrapper']),
        );
        return result.toJson();
      case StudioMethod.removeWidget:
        final result = await _api.removeWidget(
          target: WidgetRef.fromJson(params['target']),
          keepChildren: asJson<bool>(params['keepChildren']),
        );
        return result.toJson();
      case StudioMethod.reorderWidget:
        final result = await _api.reorderWidget(
          target: WidgetRef.fromJson(params['target']),
          direction: MoveDirection.fromJson(params['direction']),
        );
        return result.toJson();
      case StudioMethod.swapWidget:
        final result = await _api.swapWidget(
          target: WidgetRef.fromJson(params['target']),
          partner: SwapPartner.fromJson(params['partner']),
        );
        return result.toJson();
      case StudioMethod.undo:
        final result = await _api.undo();
        return result.toJson();
      case StudioMethod.redo:
        final result = await _api.redo();
        return result.toJson();
    }
  }
}
