import 'dart:io';

import 'step_outcome.dart';

/// One step of the quality gate, identified as `QG-NN`.
///
/// The steps are the ones of section 9.1 of the coding standard.
abstract interface class GateStep {
  /// Identifier of the step, such as `QG-01`.
  String get id;

  /// Checks the own code under [workspace] and completes with the outcome.
  ///
  /// [workspace] is the root of the pub workspace of Studio.
  Future<StepOutcome> run(Directory workspace);
}
