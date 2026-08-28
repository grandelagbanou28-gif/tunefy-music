/// Artist database record for geo-specific and niche category validation.
///
/// Each entry is a verified artist with country, genres, sub-categories,
/// confidence level, sources, and optional exclusions. This is the source of
/// truth that decides whether an item truly belongs in a category like
/// "Gospel Benin" or "Rap Français".
library;

import 'dart:convert';

/// Confidence level for an artist entry.
///
/// - `confirmed`: verified by at least 2 reliable sources.
/// - `probable`: only 1 source — accepted but flagged for manual review.
enum ConfidenceLevel {
  confirmed,
  probable;

  String get displayName => this == confirmed ? 'confirmed' : 'probable';

  static ConfidenceLevel fromString(String s) {
    return s.toLowerCase() == 'confirmed' ? confirmed : probable;
  }
}

/// A single artist record in the database.
class ArtistRecord {
  /// Unique slug identifier (e.g. "sam-bhlu").
  final String id;

  /// Official artist name (e.g. "Sam Bhlu").
  final String name;

  /// Alternative names / aliases (e.g. ["Samson Metonve Houndegla"]).
  final List<String> aliases;

  /// Country of origin (e.g. "Benin").
  final String country;

  /// Primary genres (e.g. ["gospel"]).
  final List<String> genres;

  /// Sub-categories this artist belongs to (e.g. ["Benin Gospel", "Worship"]).
  final List<String> subCategories;

  /// Confidence level: "confirmed" or "probable".
  final ConfidenceLevel confidence;

  /// URLs that justify this entry (never empty for confirmed artists).
  final List<String> sources;

  /// Date when this entry was added (ISO 8601).
  final String dateAdded;

  /// Date when this entry was last verified (ISO 8601).
  final String dateLastVerified;

  /// Optional external IDs for faster lookups.
  final Map<String, String> externalIds;

  /// Known false positives to reject explicitly (e.g. homonyme from another
  /// country). Artist names or slugs listed here are hard-rejected even if
  /// they match the name.
  final List<String> exclusions;

  const ArtistRecord({
    required this.id,
    required this.name,
    this.aliases = const [],
    required this.country,
    this.genres = const [],
    this.subCategories = const [],
    this.confidence = ConfidenceLevel.confirmed,
    this.sources = const [],
    required this.dateAdded,
    required this.dateLastVerified,
    this.externalIds = const {},
    this.exclusions = const [],
  });

  /// All name forms (official name + aliases) for matching.
  List<String> get allNames => [name, ...aliases];

  /// True if this artist is confirmed (2+ sources).
  bool get isConfirmed => confidence == ConfidenceLevel.confirmed;

  /// True if this artist belongs to the given genre.
  bool hasGenre(String genre) {
    final g = genre.toLowerCase();
    return genres.any((ag) => ag.toLowerCase() == g);
  }

  /// True if this artist belongs to the given sub-category.
  bool hasSubCategory(String sub) {
    final s = sub.toLowerCase();
    return subCategories.any((as) => as.toLowerCase() == s);
  }

  /// True if this artist belongs to the given country.
  bool hasCountry(String c) {
    return country.toLowerCase() == c.toLowerCase();
  }

  /// Create a copy with updated fields.
  ArtistRecord copyWith({
    String? id,
    String? name,
    List<String>? aliases,
    String? country,
    List<String>? genres,
    List<String>? subCategories,
    ConfidenceLevel? confidence,
    List<String>? sources,
    String? dateAdded,
    String? dateLastVerified,
    Map<String, String>? externalIds,
    List<String>? exclusions,
  }) {
    return ArtistRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      aliases: aliases ?? this.aliases,
      country: country ?? this.country,
      genres: genres ?? this.genres,
      subCategories: subCategories ?? this.subCategories,
      confidence: confidence ?? this.confidence,
      sources: sources ?? this.sources,
      dateAdded: dateAdded ?? this.dateAdded,
      dateLastVerified: dateLastVerified ?? this.dateLastVerified,
      externalIds: externalIds ?? this.externalIds,
      exclusions: exclusions ?? this.exclusions,
    );
  }

  /// Serialize to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'nom_officiel': name,
        'alias': aliases,
        'pays': country,
        'genres': genres,
        'sous_categories': subCategories,
        'niveau_confiance': confidence.displayName,
        'sources': sources,
        'date_ajout': dateAdded,
        'date_derniere_verification': dateLastVerified,
        'ids_externes': externalIds,
        'exclusions': exclusions,
      };

  /// Deserialize from JSON.
  factory ArtistRecord.fromJson(Map<String, dynamic> json) {
    return ArtistRecord(
      id: json['id'] as String,
      name: json['nom_officiel'] as String,
      aliases: (json['alias'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      country: json['pays'] as String,
      genres: (json['genres'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      subCategories: (json['sous_categories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      confidence:
          ConfidenceLevel.fromString(json['niveau_confiance'] as String? ?? 'confirmed'),
      sources: (json['sources'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      dateAdded: json['date_ajout'] as String? ?? '',
      dateLastVerified:
          json['date_derniere_verification'] as String? ?? '',
      externalIds: (json['ids_externes'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as String)) ??
          {},
      exclusions: (json['exclusions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// Deserialize a list from JSON string.
  static List<ArtistRecord> listFromJsonString(String jsonString) {
    final list = jsonDecode(jsonString) as List<dynamic>;
    return list
        .map((e) => ArtistRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Serialize a list to JSON string.
  static String listToJsonString(List<ArtistRecord> records) {
    return jsonEncode(records.map((r) => r.toJson()).toList());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtistRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ArtistRecord($id: $name, $country, $genres)';
}
