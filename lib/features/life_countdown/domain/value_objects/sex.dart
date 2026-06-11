/// Biological sex used as input to life-expectancy lookups.
///
/// "Undisclosed" is treated as the unweighted average of male and female in
/// downstream estimates so users can use Polaris without disclosing.
enum Sex {
  male('male'),
  female('female'),
  undisclosed('undisclosed');

  const Sex(this.storageKey);

  /// Stable string used for persistence; do not localize.
  final String storageKey;

  static Sex fromStorageKey(String value) {
    return Sex.values.firstWhere(
      (Sex s) => s.storageKey == value,
      orElse: () => Sex.undisclosed,
    );
  }
}
