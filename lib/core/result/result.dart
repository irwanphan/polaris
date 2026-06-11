/// A sealed value that represents either a successful value of type [T] or
/// a failure of type [F].
///
/// Polaris domain use cases return [Result] instead of throwing, so that
/// callers must handle failure explicitly. Pattern-match with `switch`:
///
/// ```dart
/// final result = await computeRemainingDays(profile);
/// switch (result) {
///   case Ok(:final value): showDays(value);
///   case Err(:final failure): showError(failure);
/// }
/// ```
sealed class Result<T, F> {
  const Result();

  /// Convenience constructor for the success case.
  const factory Result.ok(T value) = Ok<T, F>;

  /// Convenience constructor for the failure case.
  const factory Result.err(F failure) = Err<T, F>;

  /// Whether this is an [Ok].
  bool get isOk => this is Ok<T, F>;

  /// Whether this is an [Err].
  bool get isErr => this is Err<T, F>;

  /// Returns the success value or `null` if this is an [Err].
  T? get valueOrNull => switch (this) {
        Ok<T, F>(:final value) => value,
        Err<T, F>() => null,
      };

  /// Returns the failure or `null` if this is an [Ok].
  F? get failureOrNull => switch (this) {
        Err<T, F>(:final failure) => failure,
        Ok<T, F>() => null,
      };

  /// Transforms the success value while preserving the failure.
  Result<U, F> map<U>(U Function(T value) transform) => switch (this) {
        Ok<T, F>(:final value) => Ok<U, F>(transform(value)),
        Err<T, F>(:final failure) => Err<U, F>(failure),
      };

  /// Transforms the failure while preserving the success value.
  Result<T, G> mapErr<G>(G Function(F failure) transform) => switch (this) {
        Ok<T, F>(:final value) => Ok<T, G>(value),
        Err<T, F>(:final failure) => Err<T, G>(transform(failure)),
      };

  /// Folds both cases into a single value.
  R fold<R>({
    required R Function(T value) onOk,
    required R Function(F failure) onErr,
  }) =>
      switch (this) {
        Ok<T, F>(:final value) => onOk(value),
        Err<T, F>(:final failure) => onErr(failure),
      };
}

final class Ok<T, F> extends Result<T, F> {
  const Ok(this.value);
  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Ok<T, F> && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Ok($value)';
}

final class Err<T, F> extends Result<T, F> {
  const Err(this.failure);
  final F failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Err<T, F> && other.failure == failure);

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Err($failure)';
}
