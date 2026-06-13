import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

/// In-memory representation of one row from the seed dataset.
class LifeExpectancyRow {
  const LifeExpectancyRow({
    required this.countryCode,
    required this.displayName,
    required this.source,
    required this.male,
    required this.female,
  });

  final String countryCode;
  final String displayName;
  final String source;
  final double male;
  final double female;
}

/// Whole-table representation including the global fallback row.
class LifeExpectancyTable {
  const LifeExpectancyTable({required this.global, required this.byCountry});

  /// Row used when [byCountry] does not contain a country.
  final LifeExpectancyRow global;
  final List<LifeExpectancyRow> byCountry;
}

/// Reads the bundled `life_expectancy.json` asset.
///
/// Single Responsibility: load + parse. Caching, error mapping, and domain
/// projection live in the repository implementation.
class LifeExpectancyAssetDataSource {
  LifeExpectancyAssetDataSource({
    AssetBundle? assetBundle,
    this.assetPath = 'assets/seed/life_expectancy.json',
  }) : _bundle = assetBundle ?? rootBundle;

  final AssetBundle _bundle;
  final String assetPath;

  Future<LifeExpectancyTable> load() async {
    final String raw = await _bundle.loadString(assetPath);
    final Map<String, dynamic> decoded =
        json.decode(raw) as Map<String, dynamic>;

    final Map<String, dynamic> globalJson =
        decoded['global'] as Map<String, dynamic>;
    final LifeExpectancyRow global = LifeExpectancyRow(
      countryCode: '',
      displayName: 'Global average',
      source: globalJson['source'] as String,
      male: (globalJson['male'] as num).toDouble(),
      female: (globalJson['female'] as num).toDouble(),
    );

    final List<dynamic> countriesJson = decoded['byCountry'] as List<dynamic>;
    final List<LifeExpectancyRow> byCountry = countriesJson
        .cast<Map<String, dynamic>>()
        .map(_parseRow)
        .toList(growable: false);

    return LifeExpectancyTable(global: global, byCountry: byCountry);
  }

  LifeExpectancyRow _parseRow(Map<String, dynamic> json) {
    return LifeExpectancyRow(
      countryCode: json['code'] as String,
      displayName: json['displayName'] as String,
      source: json['source'] as String,
      male: (json['male'] as num).toDouble(),
      female: (json['female'] as num).toDouble(),
    );
  }
}
