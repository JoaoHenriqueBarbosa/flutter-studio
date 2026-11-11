import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_package_assets/studio_package_assets.dart';

void main() {
  // Verifies: FR-HST-001
  testWidgets('PackageAssetBinding leaves in place a binding that exists', (
    tester,
  ) async {
    final binding = PackageAssetBinding.ensureInitialized(
      packageName: 'sample_app',
    );

    expect(binding, same(tester.binding));
    expect(binding, same(WidgetsBinding.instance));
  });
}
