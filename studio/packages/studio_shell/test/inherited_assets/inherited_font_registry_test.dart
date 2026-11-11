import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_shell/studio_shell.dart';

void main() {
  // Verifies: NFR-FLEX-002
  group('InheritedFontRegistry.aliasedFamilies', () {
    final registry = InheritedFontRegistry(
      rootBundle,
      packageName: 'devtools_app',
    );

    test('indexes the fonts of the package by bare family name', () {
      final manifest = [
        {
          'family': 'packages/devtools_app/RobotoMono',
          'fonts': [
            {
              'weight': 400,
              'asset': 'packages/devtools_app/fonts/RobotoMono-Regular.ttf',
            },
            {
              'weight': 700,
              'asset': 'packages/devtools_app/fonts/RobotoMono-Bold.ttf',
            },
          ],
        },
      ];

      expect(registry.aliasedFamilies(manifest), {
        'RobotoMono': [
          'packages/devtools_app/fonts/RobotoMono-Regular.ttf',
          'packages/devtools_app/fonts/RobotoMono-Bold.ttf',
        ],
      });
    });

    test('leaves out families of the root app and of other packages', () {
      final manifest = [
        {
          'family': 'MaterialIcons',
          'fonts': [
            {'asset': 'fonts/MaterialIcons-Regular.otf'},
          ],
        },
        {
          'family': 'packages/devtools_app_shared/Roboto',
          'fonts': [
            {'asset': 'packages/devtools_app_shared/fonts/Roboto.ttf'},
          ],
        },
      ];

      expect(registry.aliasedFamilies(manifest), isEmpty);
    });

    test('returns no family for a manifest of unexpected shape', () {
      expect(registry.aliasedFamilies({'family': 'Roboto'}), isEmpty);
      expect(registry.aliasedFamilies(null), isEmpty);
    });
  });
}
