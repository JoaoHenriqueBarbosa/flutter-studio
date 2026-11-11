import 'dart:io';

/// Where the app of the project runs.
final class RunTarget {
  /// Creates the target that is the device [deviceId] of the `flutter`
  /// tool, as `flutter devices` names it (FR-HST-005).
  const RunTarget.device(this.deviceId) : toolArguments = const [];

  /// The desktop of this machine, where the app opens in its own window
  /// and needs the native toolchain to be built.
  RunTarget.desktop() : this.device(Platform.operatingSystem);

  /// The design host that needs no native toolchain: the `flutter_tester`
  /// of the SDK, which runs the app with no window (FR-HST-002, ADR-0009).
  const RunTarget.designHost()
    : deviceId = 'flutter-tester',
      // The tool lists this device only when asked to.
      toolArguments = const ['--show-test-device'];

  /// Identifier of the device.
  final String deviceId;

  /// Arguments that the `flutter` tool needs to accept the device.
  final List<String> toolArguments;

  @override
  bool operator ==(Object other) =>
      other is RunTarget && other.deviceId == deviceId;

  @override
  int get hashCode => deviceId.hashCode;

  @override
  String toString() => 'RunTarget($deviceId)';
}
