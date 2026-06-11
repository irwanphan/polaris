import 'package:polaris/core/errors/failure.dart';
import 'package:polaris/core/result/result.dart';

/// ISO-3166-1 alpha-2 country code (always uppercase, exactly 2 letters).
///
/// Value-object — equality is structural, instances are immutable.
final class CountryCode {
  const CountryCode._(this.value);

  /// Indonesia — Polaris' default market.
  static const CountryCode indonesia = CountryCode._('ID');

  final String value;

  /// Parses any 2-letter alpha string (case-insensitive) into a
  /// [CountryCode], returning [Err] on invalid input.
  static Result<CountryCode, ValidationFailure> tryParse(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.length != 2) {
      return const Result.err(
        ValidationFailure(
          message: 'Country code must be exactly 2 letters.',
          field: 'countryCode',
        ),
      );
    }
    if (!RegExp(r'^[A-Za-z]{2}$').hasMatch(trimmed)) {
      return const Result.err(
        ValidationFailure(
          message: 'Country code must contain only letters.',
          field: 'countryCode',
        ),
      );
    }
    return Result.ok(CountryCode._(trimmed.toUpperCase()));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CountryCode && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
