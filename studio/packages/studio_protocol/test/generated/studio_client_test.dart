import 'package:studio_protocol/studio_protocol.dart';
import 'package:test/test.dart';

void main() {
  group('StudioClient', () {
    const target = WidgetRef(
      uri: 'file:///work/lib/main.dart',
      position: Position(line: 11, character: 14),
      documentVersion: 1,
    );

    // Verifies: FR-API-001, NFR-MNT-006
    test('sends the parameters by name and decodes the result', () async {
      final calls = <(StudioMethod, Map<String, Object?>)>[];
      final client = StudioClient((method, params) async {
        calls.add((method, params));
        return {
          'applied': false,
          'changes': <Object?>[],
          'documentVersions': <String, Object?>{},
          'reload': 'none',
        };
      });

      final result = await client.setProperty(
        target: target,
        name: 'mainAxisAlignment',
        value: null,
      );

      expect(calls.single.$1, StudioMethod.setProperty);
      expect(calls.single.$2, {
        'target': target.toJson(),
        'name': 'mainAxisAlignment',
        'value': null,
      });
      expect(result.reload, ReloadKind.none);
    });

    // Verifies: FR-API-001
    test('decodes an absent selection as null', () async {
      final client = StudioClient((method, params) async => null);

      expect(await client.getSelection(), isNull);
    });

    // Verifies: FR-API-001
    test('a client served by a dispatcher sees what the api returns', () async {
      late final StudioDispatcher dispatcher;
      final client = StudioClient(
        (method, params) => dispatcher.dispatch(method, params),
      );
      dispatcher = StudioDispatcher(_EchoApi());

      expect(await client.select(target: target), target);
    });
  });
}

/// A [StudioApi] that selects whatever it is asked to.
final class _EchoApi implements StudioApi {
  @override
  Future<WidgetRef> select({required WidgetRef target}) async => target;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
