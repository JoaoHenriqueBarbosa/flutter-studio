import 'dart:convert';
import 'dart:io';

import 'package:studio_protocol/studio_protocol.dart';
import 'package:test/test.dart';

/// A [StudioApi] that answers each method with the result of one example
/// of the contract.
final class _ExampleApi implements StudioApi {
  const _ExampleApi(this._result);

  final Object? _result;

  @override
  Future<VersionInfo> getVersion() async => VersionInfo.fromJson(_result);

  @override
  Future<List<SourceNode>> getSourceTree({required String uri}) async => [
    for (final item in asJson<List<Object?>>(_result))
      SourceNode.fromJson(item),
  ];

  @override
  Future<List<RuntimeNode>> getRuntimeTree() async => [
    for (final item in asJson<List<Object?>>(_result))
      RuntimeNode.fromJson(item),
  ];

  @override
  Future<WidgetRef?> getSelection() async =>
      _result == null ? null : WidgetRef.fromJson(_result);

  @override
  Future<WidgetRef> select({required WidgetRef target}) async =>
      WidgetRef.fromJson(_result);

  @override
  Future<List<Property>> getProperties({required WidgetRef target}) async => [
    for (final item in asJson<List<Object?>>(_result)) Property.fromJson(item),
  ];

  @override
  Future<EditResult> setProperty({
    required WidgetRef target,
    required String name,
    required Expression? value,
  }) async => EditResult.fromJson(_result);

  @override
  Future<StructureOptions> getStructureOptions({
    required WidgetRef target,
  }) async => StructureOptions.fromJson(_result);

  @override
  Future<EditResult> wrapWidget({
    required WidgetRef target,
    required WidgetSpec wrapper,
  }) async => EditResult.fromJson(_result);

  @override
  Future<EditResult> removeWidget({
    required WidgetRef target,
    required bool keepChildren,
  }) async => EditResult.fromJson(_result);

  @override
  Future<EditResult> reorderWidget({
    required WidgetRef target,
    required MoveDirection direction,
  }) async => EditResult.fromJson(_result);

  @override
  Future<EditResult> swapWidget({
    required WidgetRef target,
    required SwapPartner partner,
  }) async => EditResult.fromJson(_result);

  @override
  Future<EditResult> extractWidget({
    required WidgetRef target,
    required String name,
  }) async => EditResult.fromJson(_result);

  @override
  Future<EditResult> convertToStatefulWidget({
    required WidgetRef declaration,
  }) async => EditResult.fromJson(_result);

  @override
  Future<EditResult> undo() async => EditResult.fromJson(_result);

  @override
  Future<EditResult> redo() async => EditResult.fromJson(_result);
}

/// One example of the contract: a call and the result it gets.
typedef _Example = ({
  String label,
  StudioMethod method,
  Map<String, Object?> params,
  Object? result,
});

List<_Example> _readExamples() {
  final Object? document = jsonDecode(
    File('studio.openrpc.json').readAsStringSync(),
  );
  return [
    if (document case {'methods': final List<Object?> methods})
      for (final method in methods)
        if (method case {
          'name': final String methodName,
          'examples': final List<Object?> examples,
        })
          for (final example in examples)
            if (example case {
              'name': final String exampleName,
              'params': final List<Object?> params,
              'result': final Map<String, Object?> result,
            })
              (
                label: '$methodName, example $exampleName',
                method: StudioMethod.values.byName(methodName),
                params: {
                  for (final param in params)
                    if (param case {
                      'name': final String name,
                      'value': final Object? value,
                    })
                      name: value,
                },
                result: result['value'],
              ),
  ];
}

void main() {
  group('StudioDispatcher', () {
    final examples = _readExamples();

    // Verifies: FR-API-001, NFR-MNT-006
    test('the contract has an example for every method', () {
      expect({
        for (final example in examples) example.method,
      }, StudioMethod.values.toSet());
    });

    for (final example in examples) {
      // Verifies: FR-API-001, NFR-MNT-006
      test('serves ${example.label}', () async {
        final dispatcher = StudioDispatcher(_ExampleApi(example.result));

        final result = await dispatcher.dispatch(
          example.method,
          example.params,
        );

        expect(jsonEquals(result, example.result), isTrue, reason: '$result');
      });
    }

    // Verifies: FR-API-001
    test('reports malformed parameters', () {
      const dispatcher = StudioDispatcher(_ExampleApi(null));

      expect(
        dispatcher.dispatch(StudioMethod.select, {'target': 'main.dart'}),
        throwsFormatException,
      );
    });
  });
}
