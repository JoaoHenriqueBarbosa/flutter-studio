import 'dart:io';

import 'structure_check.dart';
import 'workspace_packages.dart';

/// Checks that the packages depend on each other as section 6.1 of the
/// coding standard allows (CS-DSN-001).
final class DependencyGraphCheck implements StructureCheck {
  /// Creates the check.
  const DependencyGraphCheck();

  /// The packages of Studio and of the inherited code that each package of
  /// Studio may depend on. An edge that is not here needs an ADR.
  static const _allowedDependencies = {
    'studio_protocol': <String>{},
    'studio_package_assets': <String>{},
    'studio_tool': <String>{},
    'studio_design_agent': {'studio_protocol', 'studio_package_assets'},
    'studio_core': {'studio_protocol'},
    'studio_shell': {
      'studio_core',
      'studio_protocol',
      'studio_package_assets',
      'devtools_app',
      'devtools_app_shared',
      'devtools_shared',
      'devtools_extensions',
    },
  };

  static final _governedDependency = RegExp(
    r'^  ((?:studio|devtools)_\w+):',
    multiLine: true,
  );

  @override
  List<String> problemsIn(Directory workspace) {
    final packages = WorkspacePackages(workspace);
    return [
      for (final MapEntry(key: name, value: directory)
          in packages.directories.entries)
        ..._problemsOf(name, packages.manifestOf(directory)),
    ];
  }

  Iterable<String> _problemsOf(String name, String manifest) sync* {
    final allowed = _allowedDependencies[name];
    if (allowed == null) {
      yield '$name is not a package of the dependency graph.';
      return;
    }
    for (final match in _governedDependency.allMatches(manifest)) {
      final dependency = match.group(1);
      if (!allowed.contains(dependency)) {
        yield '$name depends on $dependency, outside the dependency graph.';
      }
    }
  }
}
