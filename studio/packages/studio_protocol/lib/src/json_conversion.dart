/// Returns [value] as a [T], the type that the contract gives it.
///
/// Throws a [FormatException] when [value] has another type, which is how a
/// malformed message is reported.
T asJson<T extends Object>(Object? value) {
  if (value is T) return value;
  throw FormatException('Expected $T, found ${value.runtimeType}.', value);
}

/// Whether the JSON values [left] and [right] are equal in depth.
bool jsonEquals(Object? left, Object? right) => switch ((left, right)) {
  (final List<Object?> left, final List<Object?> right) =>
    left.length == right.length &&
        Iterable<int>.generate(
          left.length,
        ).every((index) => jsonEquals(left[index], right[index])),
  (final Map<String, Object?> left, final Map<String, Object?> right) =>
    left.length == right.length &&
        left.keys.every(
          (key) => right.containsKey(key) && jsonEquals(left[key], right[key]),
        ),
  _ => left == right,
};

/// Returns a hash code of the JSON value [value] that agrees with
/// [jsonEquals].
int jsonHash(Object? value) => switch (value) {
  final List<Object?> list => Object.hashAll(list.map(jsonHash)),
  final Map<String, Object?> map => Object.hashAllUnordered(
    map.entries.map((entry) => Object.hash(entry.key, jsonHash(entry.value))),
  ),
  _ => value.hashCode,
};
