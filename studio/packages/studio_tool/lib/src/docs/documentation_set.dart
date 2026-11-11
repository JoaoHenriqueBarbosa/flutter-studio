import 'dart:io';

import 'package:path/path.dart' as path;

import '../generate/contract_document.dart';
import '../generate/generate_command.dart';
import '../verify/process_runner.dart';
import '../verify/tool_invocation.dart';
import 'service_reference.dart';

/// The generated documentation of a workspace of Studio: the reference of
/// each package, by `dart doc`, and the reference of the `Studio` service,
/// from its contract (section 8.2 of the coding standard).
final class DocumentationSet {
  /// Creates the documentation of [_workspace], generated with the tools
  /// that [_runner] runs.
  const DocumentationSet(this._workspace, this._runner);

  /// Directory of the generated documentation, relative to the workspace.
  /// It is not versioned (CS-DOC-011).
  static const outputPath = 'doc/api';

  /// What `dart doc` prints when it found nothing to report.
  static const _cleanSummary = 'Found 0 warnings and 0 errors.';

  static const _serviceReferenceFile = 'studio-service.md';

  static const _contractFile = 'studio.openrpc.json';

  final Directory _workspace;

  final ProcessRunner _runner;

  /// Generates everything and completes with one line for each problem:
  /// a package whose reference has a warning, or a tool that did not run.
  /// The list is empty when the documentation is complete.
  ///
  /// Throws a [FormatException] when the contract is invalid, and a
  /// [FileSystemException] when the workspace has no packages.
  Future<List<String>> generate() async {
    final outputDirectory = Directory(path.join(_workspace.path, outputPath))
      ..createSync(recursive: true);
    final contract = File(
      path.join(
        _workspace.path,
        GenerateCommand.protocolPackagePath,
        _contractFile,
      ),
    );
    File(path.join(outputDirectory.path, _serviceReferenceFile))
        .writeAsStringSync(
          const ServiceReference().render(
            ContractDocument.parse(contract.readAsStringSync()),
          ),
        );
    return [
      for (final package in _packages())
        ?await _documentPackage(package, outputDirectory),
    ];
  }

  List<Directory> _packages() =>
      Directory(path.join(_workspace.path, 'packages'))
          .listSync()
          .whereType<Directory>()
          .where(
            (directory) =>
                File(path.join(directory.path, 'pubspec.yaml')).existsSync(),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  /// Runs `dart doc` on [package] and returns the problem it found, or
  /// `null` when the reference has no warning.
  Future<String?> _documentPackage(
    Directory package,
    Directory outputDirectory,
  ) async {
    final name = path.basename(package.path);
    final run = await _runner.run(
      ToolInvocation('dart', [
        'doc',
        '--output',
        path.absolute(outputDirectory.path, name),
        '.',
      ]),
      workingDirectory: package,
    );
    if (run == null) return '$name: dart is not installed.';
    if (run.exitCode == 0 && run.output.contains(_cleanSummary)) return null;
    final report = run.output
        .split('\n')
        .where((line) => line.contains('warning') || line.contains('error'))
        .join('\n');
    return '$name:\n$report';
  }
}
