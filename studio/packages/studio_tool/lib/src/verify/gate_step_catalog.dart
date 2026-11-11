import '../generate/generated_code_step.dart';
import '../trace/trace_step.dart';
import 'gate_step.dart';
import 'process_runner.dart';
import 'process_step.dart';
import 'tool_invocation.dart';

/// The steps of the quality gate that are built, and the ones it requires.
final class GateStepCatalog {
  /// Creates a catalog whose steps run their tools through [_runner].
  const GateStepCatalog(this._runner);

  /// Number of steps in section 9.1 of the coding standard.
  static const _requiredStepCount = 13;

  /// Number of digits in the numeric part of a step identifier.
  static const _idDigitCount = 2;

  /// Manifest that marks a workspace with Rust code.
  static const _cargoManifest = 'Cargo.toml';

  final ProcessRunner _runner;

  /// Identifiers `QG-01` to `QG-13`, in order.
  List<String> get requiredStepIds => [
    for (var number = 1; number <= _requiredStepCount; number++)
      'QG-${'$number'.padLeft(_idDigitCount, '0')}',
  ];

  /// The steps built so far.
  List<GateStep> get steps => [
    ProcessStep(
      _runner,
      id: 'QG-01',
      invocations: const [
        ToolInvocation('dart', [
          'format',
          '--output=none',
          '--set-exit-if-changed',
          '.',
        ]),
      ],
    ),
    ProcessStep(
      _runner,
      id: 'QG-02',
      invocations: const [
        ToolInvocation('dart', ['analyze', '--fatal-infos']),
      ],
    ),
    GeneratedCodeStep(_runner),
    const TraceStep(),
    ProcessStep(
      _runner,
      id: 'QG-04',
      requiredFile: _cargoManifest,
      invocations: const [
        ToolInvocation('cargo', ['fmt', '--all', '--', '--check']),
      ],
    ),
    ProcessStep(
      _runner,
      id: 'QG-05',
      requiredFile: _cargoManifest,
      invocations: const [
        ToolInvocation('cargo', [
          'clippy',
          '--all-targets',
          '--all-features',
          '--',
          '-D',
          'warnings',
        ]),
      ],
    ),
  ];
}
