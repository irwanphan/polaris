import 'package:polaris/features/life_countdown/domain/value_objects/country_code.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/date_of_birth.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/sex.dart';

/// The user's life-countdown profile.
///
/// Only one [LifeProfile] exists at a time — Polaris is a single-user app
/// for now. Immutable; mutate via [copyWith].
final class LifeProfile {
  const LifeProfile({
    required this.dateOfBirth,
    required this.sex,
    required this.countryCode,
    required this.createdAt,
    required this.updatedAt,
    this.hideLifeCountdown = false,
  });

  final DateOfBirth dateOfBirth;
  final Sex sex;
  final CountryCode countryCode;
  final bool hideLifeCountdown;
  final DateTime createdAt;
  final DateTime updatedAt;

  LifeProfile copyWith({
    DateOfBirth? dateOfBirth,
    Sex? sex,
    CountryCode? countryCode,
    bool? hideLifeCountdown,
    DateTime? updatedAt,
  }) {
    return LifeProfile(
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      sex: sex ?? this.sex,
      countryCode: countryCode ?? this.countryCode,
      hideLifeCountdown: hideLifeCountdown ?? this.hideLifeCountdown,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LifeProfile &&
        other.dateOfBirth == dateOfBirth &&
        other.sex == sex &&
        other.countryCode == countryCode &&
        other.hideLifeCountdown == hideLifeCountdown &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    dateOfBirth,
    sex,
    countryCode,
    hideLifeCountdown,
    createdAt,
    updatedAt,
  );
}
