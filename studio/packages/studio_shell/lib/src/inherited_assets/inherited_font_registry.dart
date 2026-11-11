import 'dart:convert';

import 'package:flutter/services.dart';

/// Registers the fonts of an inherited package under their original names.
///
/// A font family declared by a dependency is bundled as
/// `packages/<package>/<family>`. The inherited code refers to the bare
/// family name, so each family is loaded again under that name (ADR-0015).
class InheritedFontRegistry {
  /// Creates a registry that reads the fonts of [packageName] from [_bundle].
  InheritedFontRegistry(this._bundle, {required String packageName})
    : _familyPrefix = 'packages/$packageName/';

  /// Key of the font manifest that the Flutter tool writes to every bundle.
  static const _fontManifestKey = 'FontManifest.json';

  final AssetBundle _bundle;

  final String _familyPrefix;

  /// Loads every family of the package under its bare name.
  ///
  /// Completes when the engine can resolve the bare names. Must complete
  /// before the first frame that uses one of them.
  Future<void> registerAliases() async {
    final Object? manifest = jsonDecode(
      await _bundle.loadString(_fontManifestKey),
    );
    await Future.wait([
      for (final MapEntry(key: family, value: assets) in aliasedFamilies(
        manifest,
      ).entries)
        _load(family, assets),
    ]);
  }

  /// Returns the asset keys of each family of the package in [manifest],
  /// indexed by bare family name.
  ///
  /// [manifest] is the decoded font manifest. Entries of other packages and
  /// entries that do not have the manifest shape are left out.
  Map<String, List<String>> aliasedFamilies(Object? manifest) {
    if (manifest is! List<Object?>) return const {};
    return {
      for (final entry in manifest)
        if (entry
            case {
              'family': final String family,
              'fonts': final List<Object?> fonts,
            }
            when family.startsWith(_familyPrefix))
          family.substring(_familyPrefix.length): [
            for (final font in fonts)
              if (font case {'asset': final String asset}) asset,
          ],
    };
  }

  Future<void> _load(String family, List<String> assets) {
    final loader = FontLoader(family);
    for (final asset in assets) {
      loader.addFont(_bundle.load(asset));
    }
    return loader.load();
  }
}
