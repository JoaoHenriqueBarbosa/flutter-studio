import 'generated/studio_error_code.dart';

/// Failure of a method of the `Studio` service, as the contract names it.
final class StudioFault implements Exception {
  /// Creates the failure [code], with the [data] that the contract gives to
  /// that error.
  const StudioFault(this.code, {this.data});

  /// Which error of the contract happened.
  final StudioErrorCode code;

  /// The data of the error, in JSON form, or `null` when there is none.
  final Object? data;

  @override
  String toString() => '${code.message}: $data';
}
