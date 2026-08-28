/// Strict multi-constraint matching for "Browse All" categories.
///
/// A category such as "Gospel Benin" is NOT a single search term: it is a
/// bundle of constraints (genre + country + language + region) that must ALL
/// be satisfied. A free-text search for "gospel" can return Indian, American,
/// Nigerian or Ghanaian gospel — none of which belong in "Gospel Benin".
///
/// This module:
///  1. Resolves the constraint bundle for any (category, sub) pair.
///  2. Builds a composite, scoped search term (e.g. "gospel benin").
///  3. Validates every candidate item against those constraints before the UI
///     ever renders it, using a confidence score. Off-country / off-genre
///     candidates are rejected instead of padding the section.
library;

import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/services/gospel_artist_database.dart';
import 'package:muzo/services/artist_database_service.dart';

/// Global reference to the artist database service.
/// Set once at app startup via [setArtistDatabaseService].
/// When null, the fallback text-based matching is used.
ArtistDatabaseService? _artistDb;

/// Set the artist database service instance (call at app startup).
void setArtistDatabaseService(ArtistDatabaseService service) {
  _artistDb = service;
}

/// Get the artist database service (may be null if not initialized).
ArtistDatabaseService? get artistDb => _artistDb;

/// A country / region with its name forms and the words that identify a song
/// as belonging to it. `name` is the canonical lowercase key used by the
/// country detection in [detectGeo].
class _Country {
  final String name;
  final List<String> markers;
  const _Country(this.name, this.markers);
}

/// Curated country/region descriptors. Markers match title / artist / album
/// text and are deliberately specific so they rarely false-positive.
const List<_Country> _countries = [
  _Country('benin', [
    'benin', 'bénin', 'beninese', 'béninois', 'béninoise', 'cotonou',
    'porto-novo', 'abomey', 'dahomey', 'pobè', 'parakou',
  ]),
  _Country('nigeria', [
    'nigeria', 'nigerian', 'lagos', 'lagos', 'naija', '9ice', 'burna boy',
    'wizkid', 'davido', 'rema', 'asake', 'omah lay',
  ]),
  _Country('ghana', [
    'ghana', 'ghanaian', 'accra', 'kumasi', 'shatta wale', 'stonebwoy',
    'sarkodie', 'black sherif', 'kidi',
  ]),
  _Country('france', [
    'france', 'french', 'français', 'française', 'francophone', 'paris',
    'ninho', 'gazo', 'sch', 'jul', 'gims', 'aya nakamura', 'lomepal',
  ]),
  _Country('usa', [
    'united states', 'usa', 'america', 'american', 'miami', 'new york',
    'atlanta', 'hollywood', 'boston',
  ]),
  _Country('uk', [
    'united kingdom', 'uk rap', 'british', 'england', 'london', 'dave ',
    'central cee', 'stormzy', 'ed sheeran',
  ]),
  _Country('jamaica', [
    'jamaica', 'jamaican', 'kingston', 'dancehall', 'reggae',
  ]),
  _Country('brazil', [
    'brazil', 'brazilian', 'brasil', 'são paulo', 'sao paulo', 'rio de janeiro',
    'funkeira', 'piseiro',
  ]),
  _Country('india', [
    'india', 'indian', 'hindi', 'bollywood', 'punjabi', 'tamil', 'telugu',
    'bhojpuri', 't-series', 'saregama', 'zee music',
  ]),
  _Country('south africa', [
    'south africa', 'south african', 'amapiano', 'johannesburg', 'cape town',
    'kwaito', 'pretoria',
  ]),
  _Country('kenya', [
    'kenya', 'kenyan', 'nairobi', 'gengetone',
  ]),
  _Country('east africa', [
    'east africa', 'east african', 'tanzania', 'tanzanian', 'uganda', 'ugandan',
    'rwanda', 'ethiopia', 'nairobi',
  ]),
  _Country('west africa', [
    'west africa', 'west african', 'afrique de l\'ouest', 'côte d\'ivoire',
    'cote d\'ivoire', 'ivorian', 'ivoirien', 'ivorian', 'senegal', 'senegalese',
    'sénégal', 'mali', 'malian', 'togo', 'burkina', 'coupé-décalé', 'coupe-decale',
  ]),
  _Country('caribbean', [
    'caribbean', 'antilles', 'guadeloupe', 'martinique', 'haiti', 'haitian',
    'zouk', 'kompa', 'soca', 'calypso',
  ]),
  _Country('africa', [
    'africa', 'african', 'afrique', 'africain', 'africaine',
  ]),
];

/// Resolved constraint bundle for one (category, sub) section.
class CategoryConstraint {
  final String category;
  final String sub;

  /// Canonical genre word (e.g. "gospel", "rap", "afrobeats"). Empty when the
  /// section is a pure region/country browse with no genre filter.
  final String genre;

  /// Canonical country/region key detected from the name (e.g. "benin").
  /// Empty when the section is not geographically scoped.
  final String geo;

  /// Words (title/artist/album) that positively identify the target geo.
  final List<String> includeMarkers;

  /// Words that identify an *other* country/region — a song carrying one of
  /// these must be rejected from a geo-scoped section.
  final List<String> excludeMarkers;

  const CategoryConstraint({
    required this.category,
    required this.sub,
    this.genre = '',
    this.geo = '',
    this.includeMarkers = const [],
    this.excludeMarkers = const [],
  });

  bool get isGeoScoped => geo.isNotEmpty;
  bool get hasGenre => genre.isNotEmpty;
  bool get isEmpty => genre.isEmpty && geo.isEmpty;
}

/// Normalize text for marker matching: lowercase, fold accents, collapse
/// spaces and punctuation so "Côte d'Ivoire" and "cote divoire" both match.
String _norm(String s) {
  return s
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('ë', 'e')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ç', 'c')
      .replaceAll('î', 'i')
      .replaceAll('ô', 'o')
      .replaceAll('ù', 'u')
      .replaceAll('û', 'u')
      .replaceAll(RegExp(r'[^a-z0-9]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool _hasAny(String haystack, List<String> markers) {
  for (final m in markers) {
    final nm = _norm(m);
    if (nm.isEmpty) continue;
    if (nm.contains(' ')) {
      if (haystack.contains(nm)) return true;
    } else {
      if (RegExp(r'(^| )' + nm + r'( |$)').hasMatch(haystack)) return true;
    }
  }
  return false;
}

/// Detect the country/region a (category, sub) name refers to, if any.
/// Matches whole words ("Benin", "Nigerian", "Rap Français") so "French Pop"
/// resolves to france and "Indian Pop" to india.
String? detectGeo(String category, String sub) {
  final text = _norm('$category $sub');
  final seen = <String, int>{};
  for (final c in _countries) {
    for (final m in c.markers) {
      final nm = _norm(m);
      if (nm.length < 3) continue;
      if (nm.contains(' ')) {
        if (text.contains(nm)) {
          seen[c.name] = (seen[c.name] ?? 0) + 1;
          break;
        }
      } else if (RegExp(r'(^| )' + nm + r'( |$)').hasMatch(text)) {
        seen[c.name] = (seen[c.name] ?? 0) + 1;
        break;
      }
    }
  }
  if (seen.isEmpty) return null;
  // Most specific wins: 'west africa' beats 'africa', 'benin' beats 'africa'.
  final sorted = seen.entries.toList()
    ..sort((a, b) {
      final lenA = a.key.split(' ').length;
      final lenB = b.key.split(' ').length;
      if (lenA != lenB) return lenB.compareTo(lenA);
      return (b.value).compareTo(a.value);
    });
  return sorted.first.key;
}

/// All markers from every country except [keep].
///
/// Region-generic descriptors ("african", "afrique", "antilles"...) are never
/// treated as "other country" evidence, and countries inside the same region
/// are kept as include markers, so "African Gospel" still accepts Nigerian or
/// Ghanaian gospel instead of rejecting it.
List<String> _includesFor(String geo) {
  final members = _regionMembers[geo];
  if (members != null) {
    final out = <String>[];
    for (final c in _countries) {
      if (c.name == geo || members.contains(c.name)) out.addAll(c.markers);
    }
    return out;
  }
  for (final c in _countries) {
    if (c.name == geo) return List.of(c.markers);
  }
  return const [];
}

/// Markers that identify a *different specific country* and therefore force a
/// reject from a [geo]-scoped section. Region descriptors and same-region
/// countries are excluded.
List<String> _excludesFor(String geo) {
  final members = _regionMembers[geo] ?? [geo];
  final out = <String>[];
  for (final c in _countries) {
    if (c.name == geo) continue;
    if (members.contains(c.name)) continue;
    // Generic region words never prove an other country.
    if (_regionMembers.containsKey(c.name)) continue;
    out.addAll(c.markers);
  }
  return out;
}

/// Country keys that are regions grouping several specific countries.
const Map<String, List<String>> _regionMembers = {
  'west africa': ['benin', 'nigeria', 'ghana'],
  'east africa': ['kenya'],
  'africa': ['benin', 'nigeria', 'ghana', 'south africa', 'kenya', 'west africa', 'east africa'],
  'caribbean': ['jamaica'],
};

/// True when [geo] is a multi-country region rather than one country.
bool _isRegion(String geo) => _regionMembers.containsKey(geo);

/// Resolve the strict constraint for a (category, sub) section.
CategoryConstraint categoryConstraintFor(String category, String sub) {
  final geo = detectGeo(category, sub);
  // Genre words that can appear inside a sub name ("Gospel", "Rap",
  // "Afrobeats", "Pop", "R&B", "Highlife", "Makossa", "Soca"...).
  final genre = _detectGenre(sub, category);
  return CategoryConstraint(
    category: category,
    sub: sub,
    genre: genre,
    geo: geo ?? '',
    includeMarkers: geo != null ? _includesFor(geo) : const [],
    excludeMarkers: geo != null ? _excludesFor(geo) : const [],
  );
}

String _detectGenre(String sub, String category) {
  final text = _norm('$sub $category');
  const genres = [
    'gospel', 'rap', 'hip hop', 'afrobeats', 'highlife', 'amapiano',
    'makossa', 'soca', 'zouk', 'kompa', 'dancehall', 'r&b', 'soul',
    'reggae', 'pop', 'rock', 'jazz', 'folk', 'country', 'classical',
    'electronic', 'techno', 'house', 'trap', 'drill', 'k-pop', 'edm',
    'bollywood', 'funk', 'cumbia', 'salsa', 'bachata', 'merengue',
    'reggaeton', 'latin',
  ];
  for (final g in genres) {
    final ng = _norm(g);
    if (RegExp(r'(^| )' + ng + r'( |$)').hasMatch(text)) return g;
  }
  return '';
}

/// Composite, scoped search term for a geo/combined section, so the backend is
/// queried with "gospel benin" — never a bare "gospel".
String buildScopedSearchTerm(String category, String sub, String fallback) {
  final c = categoryConstraintFor(category, sub);
  final parts = <String>[];
  if (c.hasGenre) parts.add(c.genre);
  if (c.geo == 'france') {
    parts.add('français');
  } else if (c.geo == 'usa') {
    parts.add('us');
  } else if (c.geo == 'uk') {
    parts.add('uk');
  } else if (c.geo.isNotEmpty) {
    parts.add(c.geo);
  }
  if (parts.isEmpty) return fallback;
  return parts.join(' ');
}

/// Confidence score for one candidate in a section. Genre and country are the
/// heavy constraints; region, language and metadata add smaller increments.
///
/// Score >= 60 → show. 40-59 → needs a second source before display. < 40 →
/// reject.
int categoryMatchScore(MuzoItem song, CategoryConstraint c) {
  final text = _norm(
    '${song.title} ${song.displayArtist} '
    '${song.channelName ?? ''} ${song.album?.name ?? ''}',
  );

  var score = 0;

  // Genre — the strongest signal. Title carrying the genre word, or a known
  // on-genre artist marker, earns the genre block.
  if (c.hasGenre) {
    final g = _norm(c.genre);
    if (text.contains(g) || text.contains(_norm('${c.genre}s'))) {
      score += 40;
    } else if (_genreArtistHint(text, c.genre)) {
      score += 40;
    }
  }

  // Country — mandatory when geo-scoped.
  if (c.isGeoScoped) {
    if (_hasAny(text, c.includeMarkers)) {
      score += 30;
    } else if (c.genre.isEmpty) {
      // Pure region browse without any country marker: keep a floor so a
      // regional section still fills with its own artists when names don't
      // carry an obvious country word (rare). No country was *guessed*.
      score += 15;
    }
    // An explicit other-country marker is a hard reject regardless of score.
    if (_hasAny(text, c.excludeMarkers)) {
      return 0;
    }
  }

  // Region / language bonus.
  if (c.geo == 'west africa' && _hasAny(text, _countries.lastWhere((x) => x.name == 'west africa').markers)) {
    score += 15;
  }
  if (c.geo == 'france' && (_hasAny(text, const ['français', 'francaise', 'french']))) {
    score += 15;
  }
  if (c.geo == 'benin' &&
      _hasAny(text, const ['cotonou', 'porto-novo', 'abomey', 'parakou', 'beninoise'])) {
    score += 15;
  }

  // Metadata completeness.
  if (song.album?.name?.isNotEmpty == true) score += 5;
  if (song.durationSeconds != null && song.durationSeconds! >= 60) score += 5;

  return score;
}

/// True when the candidate's own text is genre-confirmed: the genre word or a
/// known on-genre artist appears in the title/artist/album.
bool _genreConfirmed(String text, CategoryConstraint c) {
  if (!c.hasGenre) return false;
  final g = _norm(c.genre);
  return text.contains(g) ||
      text.contains(_norm('${c.genre}s')) ||
      _genreArtistHint(text, c.genre);
}

/// True when a genre-scoped candidate may stay. Geo-scoped sections also apply
/// the country check (hard reject on an other-country marker).
///
/// Rules (strictness is by design):
///  - any other-country marker → reject.
///  - a *confirmed gospel artist of the target country* always passes: this is
///    what makes "Benin Gospel" show Siano Bless (whose titles never say the
///    word "gospel") instead of Fanicko (R&B, not gospel). Curated per-country
///    artists live in the gospel artist database — nothing is guessed here.
///  - a confirmed gospel artist of a *different* country → reject, even if a
///    country marker is present. Nigerian gospel never fills "Benin Gospel".
///  - otherwise (unknown artist): geo-scoped sections need BOTH genre word in
///    the text AND a country marker; non-geo sections need genre confirmation.
bool acceptsForCategory(MuzoItem song, CategoryConstraint c) {
  if (c.isEmpty) return true;
  final score = categoryMatchScore(song, c);
  if (score == 0) return false;
  if (score >= 60 && !c.hasGenre) return true;

  final text = _norm(
    '${song.title} ${song.displayArtist} '
    '${song.channelName ?? ''} ${song.album?.name ?? ''}',
  );
  final primary = primaryArtistFrom(song.displayArtist);

  // ─── Priority 1: Artist database (Neon/seed) ───
  // The DB is the source of truth for geo-specific categories. If the artist
  // is found in the DB for this category, accept/reject based on the DB record.
    if (_artistDb != null) {
    final dbResult = _artistDb!.matchForCategory(
      primary,
      country: c.isGeoScoped ? c.geo : null,
      genre: c.hasGenre ? c.genre : null,
      subCategory: c.sub.isNotEmpty ? c.sub : null,
    );

    if (dbResult.matched) {
      // Artist found in DB for this category → accept.
      // If "probable", still accept but this is logged for manual review.
      return true;
    }

    // Artist explicitly excluded in DB → reject hard.
    if (dbResult.record != null && !dbResult.matched) {
      return false;
    }

    // Artist not in DB at all → fall through to text-based matching below.
  }

  final artistGeo = gospelArtistGeo(primary);

  if (!c.hasGenre) {
    // Pure country browse: a confirmed country marker is enough.
    return _hasAny(text, c.includeMarkers);
  }

  // Genre + geo (e.g. "Benin Gospel"): the artist database is authoritative.
  if (c.isGeoScoped) {
    if (artistGeo != null) {
      // Confirmed gospel artist: keep only when its country is inside the
      // target geo (Nigeria ⊂ Africa, but Nigeria ∉ Benin).
      return regionContainsGeo(c.geo, artistGeo);
    }
    // Unknown artist: require genre word + country marker together.
    return _genreConfirmed(text, c) && _hasAny(text, c.includeMarkers);
  }

  // Non-geo (pure genre): a confirmed gospel artist (e.g. Sinach — "Way
  // Maker" never says "gospel") passes; otherwise the genre word is required.
  if (artistGeo != null) return true;
  // Mainstream genres (pop, rock, jazz, dance, electronic, soul...) — a real
  // song's title rarely spells the genre word ("Blinding Lights" never says
  // "pop"), so hard-requiring the word starves the section down to novelty
  // titles that happen to literally spell it ("Soda Pop", "Pop That").
  // Gospel keeps its strict word/artist gate (authoritative DB + hints);
  // every other non-geo genre accepts a metadata-complete track as well.
  if (c.genre == 'gospel') return _genreConfirmed(text, c);
  return _genreConfirmed(text, c) || score >= 10;
}

/// Keeps only candidates that pass the strict constraint.
List<MuzoItem> filterByConstraint(
  List<MuzoItem> items,
  CategoryConstraint c,
) {
  if (c.isEmpty) return items;
  return items.where((s) => acceptsForCategory(s, c)).toList();
}

/// A few known on-genre artist name hints so an item whose title doesn't say
/// "gospel" still earns the genre block (e.g. Kirk Franklin for Gospel).
bool _genreArtistHint(String text, String genre) {
  const hints = <String, List<String>>{
    'gospel': ['kirk franklin', 'maverick city', 'tasha cobbs', 'dunsin oyekan', 'sinate ', 'elevation worship', 'bethel'],
    'rap': ['kendrick lamar', 'drake ', '21 savage', 'future ', 'metro boomin', 'lil baby', 'ninho', 'gazo', 'sch ', 'jul '],
    'afrobeats': ['burna boy', 'wizkid', 'davido', 'rema ', 'asake', 'omah lay', 'ayra starr'],
    'reggae': ['bob marley', 'damian marley', 'sizzla', 'capleton'],
    'amapiano': ['kabza de small', 'maphorisa', 'focalistic', 'sha sha'],
    'r&b': ['sza ', 'usher', 'brent faiyaz', 'giveon', 'jhene aiko'],
  };
  for (final h in hints[genre] ?? const <String>[]) {
    if (text.contains(h.trim())) return true;
  }
  return false;
}
