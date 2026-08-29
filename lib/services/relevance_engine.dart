/// Relevance engine + content audit for category sections.
///
/// Every content pipeline run tracks what was actually fetched from a source,
/// what was rejected and why, and what was accepted for display. Nothing here
/// fabricates data — it only counts real retrieval events and prints them in
/// the audit format:
///
///   CATEGORY:      <category> / <sub>
///   TOTAL FETCHED: N
///   REJECTED:      M
///   REASONS:       {wrong_country: …}
///   ACCEPTED:      K
///
/// debugPrint is a no-op in release builds, so the audit costs nothing in the
/// shipped app and runs fully in debug/profile.
library;

import 'package:flutter/foundation.dart';

/// Canonical rejection reasons (stable keys, shown in the audit reasons map).
abstract class CategoryRejectReason {
  static const String wrongCountry = 'wrong_country';
  static const String wrongGenre = 'wrong_genre';
  static const String insufficientMetadata = 'insufficient_metadata';
  static const String belowThreshold = 'below_threshold';
  static const String duplicate = 'duplicate';
  static const String notPlayable = 'not_playable';
  static const String junkTitle = 'junk_or_unresolvable';
  static const String artistLimit = 'artist_limit';
  static const String excludedArtist = 'excluded_artist';
}

/// Running counters for one (category, sub) content run.
class CategoryAudit {
  final String category;
  final String sub;

  /// Total real items fetched from source providers during this run.
  int fetched = 0;

  /// Items accepted for display after all gates.
  int accepted = 0;

  final Map<String, int> _rejected = {};

  CategoryAudit({required this.category, required this.sub});

  void onFetched(int n) => fetched += n;

  void rejectedBecause(String reason) =>
      _rejected.update(reason, (v) => v + 1, ifAbsent: () => 1);

  void onAccepted([int n = 1]) => accepted += n;

  int get rejected => _rejected.values.fold(0, (a, b) => a + b);

  /// Prints the audit block in the required format. Debug-only.
  void report([String? scope]) {
    final label = scope == null ? '$category/$sub' : '$category/$sub ($scope)';
    debugPrint('[Audit] CATEGORY: $label');
    debugPrint('[Audit] TOTAL FETCHED: $fetched');
    debugPrint('[Audit] REJECTED: $rejected');
    debugPrint(
        '[Audit] REASONS: {${_rejected.entries.map((e) => '${e.key}: ${e.value}').join(', ')}}');
    debugPrint('[Audit] ACCEPTED: $accepted');
  }
}