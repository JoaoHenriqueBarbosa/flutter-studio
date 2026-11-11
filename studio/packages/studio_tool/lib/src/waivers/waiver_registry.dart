import 'dart:io';

/// The registry of waivers of the coding standard, read from
/// `docs/engineering/waivers.md` (section 9.4 of the coding standard).
final class WaiverRegistry {
  const WaiverRegistry._(this.validUntil);

  /// Reads the registry from [file]. A file that does not exist is a
  /// registry with no waiver.
  factory WaiverRegistry.read(File file) {
    final validUntil = <String, DateTime?>{};
    if (!file.existsSync()) return WaiverRegistry._(validUntil);
    for (final line in file.readAsLinesSync()) {
      final id = _row.firstMatch(line)?.group(1);
      if (id == null) continue;
      final date = _date.firstMatch(line.split('|').reversed.skip(1).first);
      validUntil[id] = date == null
          ? null
          : DateTime(
              int.parse(date.group(3) ?? ''),
              int.parse(date.group(2) ?? ''),
              int.parse(date.group(1) ?? ''),
            );
    }
    return WaiverRegistry._(validUntil);
  }

  /// Form of the identifier of a waiver.
  static const identifierPattern = r'WVR-\d{3}';

  static final _row = RegExp('^\\|\\s*($identifierPattern)\\s*\\|');

  static final _date = RegExp(r'(\d{2})/(\d{2})/(\d{4})');

  /// Last day of validity of each waiver, by identifier, or `null` for a
  /// waiver whose validity is a condition and not a date.
  final Map<String, DateTime?> validUntil;

  /// Whether the registry has the waiver [id].
  bool contains(String id) => validUntil.containsKey(id);

  /// Whether the waiver [id] has a date of validity before [today].
  bool isExpired(String id, DateTime today) =>
      validUntil[id]?.isBefore(today) ?? false;
}
