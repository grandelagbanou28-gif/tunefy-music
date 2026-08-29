/// A `genre_catalog.dart` — real, multi-source music engine (keyless).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muzo/services/audius_api_service.dart';
import 'package:muzo/services/jamendo_api_service.dart';
import 'package:muzo/services/ccmixter_api_service.dart';
import 'package:muzo/services/internet_archive_service.dart';
import 'package:muzo/services/itunes_api_service.dart';
import 'package:muzo/models/muzo_item.dart';

class GenrePlan {
  final String key;
  final String? jamendoTag;
  final List<String> audiusGenres;
  final String ytifyTerm;
  final String itunesTerm;
  final bool ambient;

  const GenrePlan({
    required this.key,
    this.jamendoTag,
    this.audiusGenres = const [],
    required this.ytifyTerm,
    String? itunesTerm,
    this.ambient = false,
  }) : itunesTerm = itunesTerm ?? ytifyTerm;

  static const GenrePlan none = GenrePlan(key: '', ytifyTerm: '');

  bool get isEmpty => key.isEmpty;
}

const GenrePlan none = GenrePlan.none;

/// Audius' genre filter is case-sensitive and its catalog only covers some
/// genres; we always query its canonical spelling so "hip hop" -> "Hip-Hop/Rap".
const String audiusGenreNone = '';

/// Canonical genre beacons: the genre word a section must play, expressed in
/// each backend's vocabulary. `key` is store-normalized for overrides.
class _Beacon {
  final String key;
  final String? jamendo;
  final List<String> audius;
  final String ytify;
  const _Beacon(this.key, {this.jamendo, this.audius = const [], this.ytify = ''});
}

const List<_Beacon> _beacons = [
  _Beacon('pop', jamendo: 'pop', audius: ['Pop'], ytify: 'pop'),
  _Beacon('romance', jamendo: 'pop', audius: ['R&B/Soul'], ytify: 'romantic love songs'),
  _Beacon('romantic', jamendo: 'pop', audius: ['R&B/Soul'], ytify: 'romantic love songs'),
  _Beacon('hip hop', jamendo: 'hiphop', audius: ['Hip-Hop/Rap'], ytify: 'hip hop'),
  _Beacon('rap', jamendo: 'hiphop', audius: ['Hip-Hop/Rap'], ytify: 'rap'),
  _Beacon('r&b', jamendo: 'rnb', audius: ['R&B/Soul'], ytify: 'r&b'),
  _Beacon('soul', jamendo: 'soul', audius: ['Soul'], ytify: 'soul'),
  _Beacon('rock', jamendo: 'rock', audius: ['Rock'], ytify: 'rock'),
  _Beacon('metal', jamendo: 'metal', audius: ['Metal'], ytify: 'metal'),
  _Beacon('jazz', jamendo: 'jazz', audius: ['Jazz'], ytify: 'jazz'),
  _Beacon('blues', jamendo: 'blues', audius: [], ytify: 'blues'),
  _Beacon('classical', jamendo: 'classical', audius: ['Classical'], ytify: 'classical'),
  _Beacon('electronic', jamendo: 'electronic', audius: ['Electronic'], ytify: 'electronic music'),
  _Beacon('edm', jamendo: 'electronic', audius: [], ytify: 'edm'),
  _Beacon('reggae', jamendo: 'reggae', audius: ['Reggae'], ytify: 'reggae'),
  _Beacon('country', jamendo: 'country', audius: ['Country'], ytify: 'country'),
  _Beacon('folk', jamendo: 'folk', audius: ['Folk'], ytify: 'folk'),
  _Beacon('latin', jamendo: 'latin', audius: ['Latin'], ytify: 'latin'),
  _Beacon('gospel', jamendo: 'christian', audius: [], ytify: 'gospel'),
  _Beacon('christian', jamendo: 'christian', audius: [], ytify: 'christian worship'),
  _Beacon('afro', jamendo: 'africa', audius: [], ytify: 'afrobeats'),
  _Beacon('afrobeats', jamendo: 'africa', audius: [], ytify: 'afrobeats'),
  _Beacon('amapiano', jamendo: 'africa', audius: [], ytify: 'amapiano'),
  _Beacon('ambient', jamendo: 'ambient', audius: ['Ambient'], ytify: 'ambient'),
  _Beacon('chill', jamendo: 'chill', audius: [], ytify: 'chill'),
  _Beacon('lofi', jamendo: 'chill', audius: [], ytify: 'lofi'),
  _Beacon('meditation', jamendo: 'ambient', audius: [], ytify: 'meditation music'),
  _Beacon('funk', jamendo: null, audius: ['Funk'], ytify: 'funk'),
  _Beacon('salsa', jamendo: 'latin', audius: [], ytify: 'salsa'),
  _Beacon('bachata', jamendo: 'latin', audius: [], ytify: 'bachata'),
  _Beacon('reggaeton', jamendo: 'latin', audius: [], ytify: 'reggaeton'),
  _Beacon('cumbia', jamendo: 'latin', audius: [], ytify: 'cumbia'),
  _Beacon('merengue', jamendo: 'latin', audius: [], ytify: 'merengue'),
  _Beacon('soca', jamendo: 'africa', audius: [], ytify: 'soca'),
  _Beacon('zouk', jamendo: 'africa', audius: [], ytify: 'zouk'),
  _Beacon('kompa', jamendo: 'africa', audius: [], ytify: 'kompa'),
  _Beacon('dancehall', jamendo: 'africa', audius: ['Dancehall'], ytify: 'dancehall'),
  _Beacon('k-pop', jamendo: 'pop', audius: [], ytify: 'kpop'),
  _Beacon('trance', jamendo: 'electronic', audius: ['Trance'], ytify: 'trance'),
  _Beacon('techno', jamendo: 'electronic', audius: ['Techno'], ytify: 'techno'),
  _Beacon('house', jamendo: 'electronic', audius: ['House'], ytify: 'house music'),
  _Beacon('drum & bass', jamendo: 'electronic', audius: ['Drum & Bass'], ytify: 'drum and bass'),
  _Beacon('dubstep', jamendo: 'electronic', audius: ['Dubstep'], ytify: 'dubstep'),
  _Beacon('trap', jamendo: 'hiphop', audius: ['Trap'], ytify: 'trap'),
  _Beacon('drill', jamendo: 'hiphop', audius: [], ytify: 'drill'),
  _Beacon('rave', jamendo: 'electronic', audius: [], ytify: 'rave'),
  _Beacon('disco', jamendo: 'electronic', audius: ['Disco'], ytify: 'disco'),
  _Beacon('sleep', jamendo: 'ambient', audius: [], ytify: 'sleep music', ),
  _Beacon('study', jamendo: 'ambient', audius: [], ytify: 'study music'),
  _Beacon('focus', jamendo: 'ambient', audius: [], ytify: 'focus music'),
  _Beacon('lounge', jamendo: 'chill', audius: [], ytify: 'lounge music'),
  _Beacon('bollywood', jamendo: 'newage', audius: [], ytify: 'bollywood'),
  _Beacon('desi', jamendo: 'newage', audius: [], ytify: 'desi'),
  _Beacon('gaming', jamendo: 'electronic', audius: [], ytify: 'gaming music'),
];

final Map<String, _Beacon> _beaconByKey =
    {for (final b in _beacons) _canon(b.key): b};

/// Normalize any section term to a canonical beacon key: lowercase, no
/// accents, non-alphanumerics folded to a single space so "Hip-Hop" matches
/// the "hip hop" beacon exactly as "R&B" matches "r&b".
String _canon(String s) {
  return s
      .trim()
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('à', 'a')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Strict (category, sub) overrides for sub-genres that must be exact, so the
/// section never degrades to the parent genre's generic playlist.
const Map<String, GenrePlan> _overrides = {
  // ─── Gospel ───
  'gospel|gospel hits': GenrePlan(
    key: 'gospel hits',
    jamendoTag: 'christian',
    ytifyTerm: 'gospel',
  ),
  'gospel|contemporary gospel': GenrePlan(
    key: 'contemporary gospel',
    jamendoTag: 'christian',
    ytifyTerm: 'contemporary gospel',
  ),
  'gospel|nigerian gospel': GenrePlan(
    key: 'nigerian gospel',
    jamendoTag: 'christian',
    ytifyTerm: 'nigerian gospel',
  ),
  'gospel|benin gospel': GenrePlan(
    key: 'benin gospel',
    jamendoTag: 'christian',
    ytifyTerm: 'benin gospel',
  ),
  'gospel|gospel worship': GenrePlan(
    key: 'gospel worship',
    jamendoTag: 'worship',
    ytifyTerm: 'gospel worship',
  ),

  // ─── Afro ───
  'afro hits|amapiano': GenrePlan(
    key: 'amapiano',
    jamendoTag: 'africa',
    audiusGenres: [],
    ytifyTerm: 'amapiano',
  ),
  'afro hits|afro house': GenrePlan(
    key: 'afro house',
    jamendoTag: 'africa',
    audiusGenres: [],
    ytifyTerm: 'afro house',
  ),
  'afro hits|african gospel': GenrePlan(
    key: 'african gospel',
    jamendoTag: 'christian',
    audiusGenres: [],
    ytifyTerm: 'african gospel',
  ),
  'afro hits|east africa': GenrePlan(
    key: 'east africa',
    jamendoTag: 'africa',
    audiusGenres: [],
    ytifyTerm: 'east african music',
  ),
  'afro hits|west africa': GenrePlan(
    key: 'west africa',
    jamendoTag: 'africa',
    audiusGenres: [],
    ytifyTerm: 'west african music',
  ),
  'afrobeats|afro r b': GenrePlan(
    key: 'afro rnb',
    jamendoTag: 'africa',
    audiusGenres: [],
    ytifyTerm: 'afro r&b',
  ),
  'afrobeats|afro fusion': GenrePlan(
    key: 'afro fusion',
    jamendoTag: 'africa',
    audiusGenres: [],
    ytifyTerm: 'afro fusion',
  ),

  // ─── Latin ───
  'latin|salsa': GenrePlan(
    key: 'salsa',
    jamendoTag: 'latin',
    ytifyTerm: 'salsa music',
  ),
  'latin|bachata': GenrePlan(
    key: 'bachata',
    jamendoTag: 'latin',
    ytifyTerm: 'bachata',
  ),
  'latin|reggaeton': GenrePlan(
    key: 'reggaeton',
    jamendoTag: 'latin',
    ytifyTerm: 'reggaeton',
  ),
  'latin|latin trap': GenrePlan(
    key: 'latin trap',
    jamendoTag: 'latin',
    ytifyTerm: 'latin trap',
  ),
  'latin|regional mexican': GenrePlan(
    key: 'regional mexican',
    jamendoTag: 'latin',
    ytifyTerm: 'regional mexican',
  ),
  'latin|corridos': GenrePlan(
    key: 'corridos',
    jamendoTag: 'latin',
    ytifyTerm: 'corridos',
  ),
  'latin|brazilian': GenrePlan(
    key: 'brazilian',
    jamendoTag: 'latin',
    ytifyTerm: 'brazilian music',
    audiusGenres: [],
  ),

  // ─── Hip-Hop sub-genres stay on genre ───
  'hip hop|trap': GenrePlan(
    key: 'trap',
    jamendoTag: 'hiphop',
    audiusGenres: ['Trap'],
    ytifyTerm: 'trap music',
  ),
  'hip hop|drill': GenrePlan(
    key: 'drill',
    jamendoTag: 'hiphop',
    audiusGenres: [],
    ytifyTerm: 'drill rap',
  ),
  'hip hop|boom bap': GenrePlan(
    key: 'boom bap',
    jamendoTag: 'hiphop',
    audiusGenres: [],
    ytifyTerm: 'boom bap',
  ),
  'hip hop|conscious hip hop': GenrePlan(
    key: 'conscious hip hop',
    jamendoTag: 'hiphop',
    audiusGenres: ['Hip-Hop/Rap'],
    ytifyTerm: 'conscious hip hop',
  ),
  'hip hop|french hip hop': GenrePlan(
    key: 'french hip hop',
    jamendoTag: 'hiphop',
    audiusGenres: [],
    ytifyTerm: 'rap français',
  ),

  // ─── Electronic/House/EDM stay EDM-scoped ───
  'electronic|edm': GenrePlan(
    key: 'edm',
    jamendoTag: 'electronic',
    audiusGenres: [],
    ytifyTerm: 'edm',
  ),
  'electronic|dubstep': GenrePlan(
    key: 'dubstep',
    jamendoTag: 'electronic',
    audiusGenres: ['Dubstep'],
    ytifyTerm: 'dubstep',
  ),
  'electronic|drum bass': GenrePlan(
    key: 'drum and bass',
    jamendoTag: 'electronic',
    audiusGenres: ['Drum & Bass'],
    ytifyTerm: 'drum and bass',
  ),
  'house|deep house': GenrePlan(
    key: 'deep house',
    jamendoTag: 'electronic',
    audiusGenres: ['Deep House'],
    ytifyTerm: 'deep house',
  ),
  'house|tech house': GenrePlan(
    key: 'tech house',
    jamendoTag: 'electronic',
    audiusGenres: ['House'],
    ytifyTerm: 'tech house',
  ),
  'house|tropical house': GenrePlan(
    key: 'tropical house',
    jamendoTag: 'electronic',
    audiusGenres: [],
    ytifyTerm: 'tropical house',
  ),

  // ─── Ambient / Focus / Sleep ───
  'focus|white noise': GenrePlan(
    key: 'white noise',
    jamendoTag: 'ambient',
    audiusGenres: [],
    ytifyTerm: 'white noise',
    ambient: true,
  ),
  'meditation|guided meditation': GenrePlan(
    key: 'guided meditation',
    jamendoTag: 'ambient',
    audiusGenres: [],
    ytifyTerm: 'guided meditation',
    ambient: true,
  ),
  'meditation|nature sounds': GenrePlan(
    key: 'nature sounds',
    jamendoTag: 'ambient',
    audiusGenres: [],
    ytifyTerm: 'nature sounds',
    ambient: true,
  ),
  'sleep|asmr': GenrePlan(
    key: 'asmr',
    jamendoTag: 'ambient',
    audiusGenres: [],
    ytifyTerm: 'asmr',
    ambient: true,
  ),

  // ─── Gaming ───
  'gaming|game soundtracks': GenrePlan(
    key: 'game soundtracks',
    jamendoTag: 'electronic',
    audiusGenres: [],
    ytifyTerm: 'video game soundtrack',
  ),

  // ─── Romance / Love: real love-song terms across every source, so the
  // sections stay genre-exact instead of falling back to generic mixed pop. ───
  'mood|romantic': GenrePlan(
    key: 'romantic',
    jamendoTag: 'pop',
    audiusGenres: ['R&B/Soul'],
    ytifyTerm: 'romantic love songs',
  ),
  'romance|romantic pop': GenrePlan(
    key: 'romantic pop',
    jamendoTag: 'pop',
    audiusGenres: ['Pop'],
    ytifyTerm: 'romantic pop',
  ),
  'romance / love|romantic pop': GenrePlan(
    key: 'romantic pop',
    jamendoTag: 'pop',
    audiusGenres: ['Pop'],
    ytifyTerm: 'romantic pop',
  ),
  'romance|love songs': GenrePlan(
    key: 'love songs',
    jamendoTag: 'pop',
    audiusGenres: ['R&B/Soul'],
    ytifyTerm: 'love songs',
  ),
  'romance / love|love songs': GenrePlan(
    key: 'love songs',
    jamendoTag: 'pop',
    audiusGenres: ['R&B/Soul'],
    ytifyTerm: 'love songs',
  ),
  'romance|r&b love': GenrePlan(
    key: 'r&b love',
    jamendoTag: 'rnb',
    audiusGenres: ['R&B/Soul'],
    ytifyTerm: 'r&b love songs',
  ),
  'romance|slow jams': GenrePlan(
    key: 'slow jams',
    jamendoTag: 'rnb',
    audiusGenres: [],
    ytifyTerm: 'slow jams',
  ),
  'romance|afro love': GenrePlan(
    key: 'afro love',
    jamendoTag: 'africa',
    audiusGenres: [],
    ytifyTerm: 'afro love songs',
  ),
  'romance / love|afro love': GenrePlan(
    key: 'afro love',
    jamendoTag: 'africa',
    audiusGenres: [],
    ytifyTerm: 'afro love songs',
  ),
  'romance|french love': GenrePlan(
    key: 'french love',
    jamendoTag: 'pop',
    audiusGenres: [],
    ytifyTerm: 'french love songs',
  ),
  'romance / love|french love': GenrePlan(
    key: 'french love',
    jamendoTag: 'pop',
    audiusGenres: [],
    ytifyTerm: 'french love songs',
  ),
  'romance|wedding': GenrePlan(
    key: 'wedding',
    jamendoTag: 'pop',
    audiusGenres: [],
    ytifyTerm: 'wedding songs',
  ),
  'romance / love|wedding': GenrePlan(
    key: 'wedding',
    jamendoTag: 'pop',
    audiusGenres: [],
    ytifyTerm: 'wedding songs',
  ),
  'romance|heartbreak': GenrePlan(
    key: 'heartbreak',
    jamendoTag: 'pop',
    audiusGenres: [],
    ytifyTerm: 'heartbreak songs',
  ),
  'romance / love|heartbreak': GenrePlan(
    key: 'heartbreak',
    jamendoTag: 'pop',
    audiusGenres: [],
    ytifyTerm: 'heartbreak songs',
  ),
  'romance|valentine\'s day': GenrePlan(
    key: 'valentines day',
    jamendoTag: 'pop',
    audiusGenres: [],
    ytifyTerm: 'valentines day songs',
  ),
  'romance|first love': GenrePlan(
    key: 'first love',
    jamendoTag: 'pop',
    audiusGenres: [],
    ytifyTerm: 'first love songs',
  ),
  'romance|couple': GenrePlan(
    key: 'couple',
    jamendoTag: 'pop',
    audiusGenres: [],
    ytifyTerm: 'couple songs',
  ),
};

/// Resolve the genre plan for a (category, sub) section.
/// Priority: exact override -> beacon on sub -> beacon on category -> word scan.
GenrePlan genrePlanFor(String category, String sub) {
  final cat = _canon(category.trim());
  final sb = _canon(sub.trim());

  if (cat.isEmpty && sb.isEmpty) return none;
  final overrideKey = '$cat|$sb';
  final override = _overrides[overrideKey];
  if (override != null) return override;

  GenrePlan? fromBeacon(String key) {
    if (key.isEmpty) return null;
    final b = _beaconByKey[key];
    if (b == null) return null;
    return GenrePlan(
      key: b.key,
      jamendoTag: b.jamendo,
      audiusGenres: b.audius,
      ytifyTerm: b.ytify.isEmpty ? b.key : b.ytify,
      ambient: _isAmbientTerm(b.key),
    );
  }

  GenrePlan? byWord(String s) {
    for (final b in _beacons) {
      if (s.contains(_canon(b.key))) {
        return fromBeacon(b.key);
      }
    }
    return null;
  }

  // Sub-category's own genre wins (e.g. Gospel > Gospel Hits -> gospel).
  final subBeacon = fromBeacon(sb) ?? byWord(sb);
  if (subBeacon != null && !subBeacon.isEmpty) return subBeacon;

  // Otherwise the parent category is the genre scope.
  final catBeacon = fromBeacon(cat) ?? byWord(cat);
  if (catBeacon != null && !catBeacon.isEmpty) return catBeacon;

  // Pure term fallback: the section IS a genre noun itself (e.g. "Salsa").
  final term = sb.isNotEmpty ? sb : cat;
  final termBeacon = byWord(term);
  if (termBeacon != null) return termBeacon;

  return none;
}

bool _isAmbientTerm(String key) {
  return _ambientKeys.contains(key);
}

const Set<String> _ambientKeys = {
  'sleep',
  'meditation',
  'focus',
  'study',
  'lofi',
  'ambient',
  'chill',
  'lounge',
  'rave',
};

/// Shared keyless provider for the iTunes Search API layer (FR + US stores).
final itunesApiServiceProvider = Provider<ItunesApiService>((ref) {
  return ItunesApiService();
});

/// Convenience: does this (category, sub) carry a known genre plan?
bool hasGenrePlan(String category, String sub) =>
    !genrePlanFor(category, sub).isEmpty;

/// Fetch a genre-exact batch mixing Jamendo tag + Audius genre + iTunes term +
/// ccMixter tags + Internet Archive collections, in parallel. Used by section
/// providers instead of the old generic "hits/trending" fallback that produced
/// off-genre content. ccMixter and Internet Archive return directly-streamable
/// full-length real files (user_track), so they are genuinely playable.
Future<List<MuzoItem>> fetchGenreBatch(
  Ref ref,
  GenrePlan plan, {
  int perSource = 6,
}) async {
  if (plan.isEmpty) return const [];
  final jamendo = ref.read(jamendoApiServiceProvider);
  final audius = ref.read(audiusApiServiceProvider);
  final itunes = ref.read(itunesApiServiceProvider);
  final ccmixter = ref.read(ccmixterApiServiceProvider);
  final ia = ref.read(internetArchiveServiceProvider);

  final futures = <Future<List<MuzoItem>>>[
    if (plan.jamendoTag != null)
      jamendo
          .tracksByTag(plan.jamendoTag!, limit: perSource)
          .then((t) => t.map((t) => t.toMuzoItem()).toList()),
    for (final g in plan.audiusGenres)
      audius.tracksByGenre(g, limit: perSource).then((t) {
        return t.map((t) => t.toMuzoItem()).toList();
      }),
    itunes.searchSongsFrUs(plan.itunesTerm, limit: perSource),
    // Full-length CC-licensed real files.
    ccmixter.tracksByTag(plan.ytifyTerm, limit: perSource),
    // Real audio collections from the Internet Archive (first N).
    ia.audioByTerm(plan.ytifyTerm, limit: perSource <= 4 ? perSource : 4),
  ];

  final batches = await Future.wait(futures);
  final seen = <String>{};
  final out = <MuzoItem>[];
  for (final batch in batches) {
    for (final song in batch) {
      final key = (song.videoId ?? '${song.title}|${song.displayArtist}')
          .toLowerCase();
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      out.add(song);
    }
  }
  return out;
}