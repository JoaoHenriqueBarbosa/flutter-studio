/// Version of a Flutter SDK, reduced to the numbers that order releases.
final class SdkVersion {
  /// Creates the version `major.minor.patch`.
  const SdkVersion(this.major, this.minor, this.patch);

  /// First number of the version.
  final int major;

  /// Second number of the version. A stable release line is a major and a
  /// minor number.
  final int minor;

  /// Third number of the version.
  final int patch;

  /// Parses [text], such as `3.47.9` or `3.50.0-1.0.pre-437`.
  ///
  /// Returns `null` when [text] does not start with three numbers separated
  /// by dots. A pre-release suffix is ignored.
  static SdkVersion? tryParse(String text) {
    final numbers = [
      for (final part in text.split('-').first.split('.')) int.tryParse(part),
    ];
    return switch (numbers) {
      [final major?, final minor?, final patch?] => SdkVersion(
        major,
        minor,
        patch,
      ),
      _ => null,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is SdkVersion &&
      other.major == major &&
      other.minor == minor &&
      other.patch == patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}
