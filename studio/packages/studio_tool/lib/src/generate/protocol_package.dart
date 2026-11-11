import 'dart:io';

import 'package:path/path.dart' as path;

import '../verify/process_runner.dart';
import '../verify/tool_invocation.dart';
import 'contract_document.dart';
import 'contract_generator.dart';

/// The `studio_protocol` package on disk: its contract and the Dart files
/// generated from it.
final class ProtocolPackage {
  /// Creates the package at [_rootPath], formatting through [_runner].
  const ProtocolPackage(this._rootPath, this._runner);

  static const _contractFile = 'studio.openrpc.json';

  /// Where a check writes what the contract generates, inside the package
  /// so that the formatter reads the same configuration.
  static const _scratchDirectory = '.dart_tool/st_generate';

  final String _rootPath;

  final ProcessRunner _runner;

  String get _libraryPath => path.join(_rootPath, 'lib');

  /// Generates the files and writes them over the ones in the package.
  ///
  /// Throws a [FormatException] when the contract is invalid.
  Future<void> generate() async {
    final directory = Directory(
      path.join(_libraryPath, ContractGenerator.generatedDirectory),
    );
    if (directory.existsSync()) directory.deleteSync(recursive: true);
    await _write(_libraryPath);
  }

  /// Generates the files apart and completes with the paths, relative to
  /// `lib/`, of the ones that differ from the package (CS-DRY-013).
  ///
  /// A file that exists only on one of the two sides differs. Throws a
  /// [FormatException] when the contract is invalid.
  Future<List<String>> findDifferences() async {
    final scratch = Directory(path.join(_rootPath, _scratchDirectory));
    if (scratch.existsSync()) scratch.deleteSync(recursive: true);
    final expected = await _write(scratch.path);
    final present = _generatedFilesUnder(_libraryPath);
    final differing = [
      for (final name in {...expected.keys, ...present}.toList()..sort())
        if (_read(scratch.path, name) != _read(_libraryPath, name)) name,
    ];
    scratch.deleteSync(recursive: true);
    return differing;
  }

  /// Writes the generated files under [libraryPath], formats them and
  /// returns what was generated.
  Future<Map<String, String>> _write(String libraryPath) async {
    final contract = File(path.join(_rootPath, _contractFile));
    final files = const ContractGenerator().generate(
      ContractDocument.parse(contract.readAsStringSync()),
      handwrittenSources: _handwrittenSources(),
    );
    for (final MapEntry(key: name, value: source) in files.entries) {
      File(path.join(libraryPath, name))
        ..createSync(recursive: true)
        ..writeAsStringSync(source);
    }
    final run = await _runner.run(
      ToolInvocation('dart', ['format', path.absolute(libraryPath)]),
      workingDirectory: Directory(_rootPath),
    );
    if (run == null || run.exitCode != 0) {
      throw FormatException('dart format failed.', run?.output);
    }
    return files;
  }

  List<String> _handwrittenSources() => [
    for (final entity in Directory(path.join(_libraryPath, 'src')).listSync())
      if (entity is File && entity.path.endsWith('.dart'))
        'src/${path.basename(entity.path)}',
  ];

  Set<String> _generatedFilesUnder(String libraryPath) {
    final directory = Directory(
      path.join(libraryPath, ContractGenerator.generatedDirectory),
    );
    return {
      if (directory.existsSync())
        for (final entity in directory.listSync())
          path.relative(entity.path, from: libraryPath),
    };
  }

  String? _read(String libraryPath, String name) {
    final file = File(path.join(libraryPath, name));
    return file.existsSync() ? file.readAsStringSync() : null;
  }
}
