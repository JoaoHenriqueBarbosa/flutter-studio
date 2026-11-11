import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/sample_contract.dart';

void main() {
  group('ServiceEmitter', () {
    final files = ServiceEmitter(sampleContract).emit();

    // Verifies: NFR-MNT-006
    test('writes the interface with one documented method for each', () {
      expect(
        files['sample_api.dart'],
        allOf(
          contains('abstract interface class SampleApi {'),
          contains('  /// Renames a thing.\n'),
          contains('  /// The parameter [label]: the new label.\n'),
          contains('  /// Errors: `NotFound`.\n'),
          contains(
            'Future<Thing> rename({required Thing thing, String? label,});',
          ),
        ),
      );
    });

    // Verifies: NFR-MNT-006
    test('writes the client that encodes the parameters by name', () {
      expect(
        files['sample_client.dart'],
        allOf(
          contains('final class SampleClient implements SampleApi {'),
          contains("{'thing': thing.toJson(),'label': ?label,}"),
          contains('return Thing.fromJson(result);'),
        ),
      );
    });

    // Verifies: NFR-MNT-006
    test('writes the dispatcher that decodes the parameters', () {
      expect(
        files['sample_dispatcher.dart'],
        allOf(
          contains('case SampleMethod.rename:'),
          contains("thing: Thing.fromJson(params['thing']),"),
          contains('return result.toJson();'),
        ),
      );
    });
  });
}
