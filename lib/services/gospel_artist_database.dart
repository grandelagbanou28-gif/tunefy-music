/// Curated, country-scoped genre artist database.
///
/// This is the source of truth that decides whether an item truly belongs in a
/// (genre, country) section such as "Gospel > Benin Gospel". The list is
/// manually curated from verifiable sources — it must NOT be guessed. An artist
/// who merely lives in / is popular in a country but whose primary music is a
/// different genre (e.g. Fanicko is R&B/afrobeat, not gospel) is excluded.
///
/// Matching is fuzzy: "Siano Bless Officiel", "Siano Bless - Topic" and
/// "Siano Bless" all resolve to the same curated artist.
library;

/// Local normalizer (kept independent of [strict_category_filter] so this
/// module can be imported without exposing private members).
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

/// Confirmed gospel artists, keyed by their canonical country/region key (the
/// same keys used by `detectGeo`). Artists whose career is primarily a
/// different genre are deliberately absent.
const Map<String, List<String>> _gospelByGeo = {
  // ─── Bénin ───
  // Verified gospel artists / chantres: Siano Bless, Anna Tèko, Sam Bhlu,
  // Yvan pour Yésué, Sir Abilé, Paul Kouton, Alphonse Gandonou, Désiré
  // Kindomihou, Jonny Sourou, Miriam Ayizansi, Sandra Heriti, Sessimè,
  // Kinzah, Félix Didolanvi, Arnauld Migan, Kinivi, Dossi.
  // NOT gospel (excluded): Fanicko (R&B/hip-hop), Axel Merryl (afrobeats),
  // Vano Baby (urbain), T-Gang (rap).
  'benin': [
    'Siano Bless',
    'Anna Tèko',
    'Anna Teko',
    'Zeynab Habib',
    'Sam Bhlu',
    'Yvan pour Yésué',
    'Yvan pour Yesue',
    'Sir Abilé',
    'Sir Abile',
    'Paul Kouton',
    'Alphonse Gandonou',
    'Désiré Kindomihou',
    'Desire Kindomihou',
    'Jonny Sourou',
    'Miriam Ayizansi',
    'Sandra Heriti',
    'Sessimè',
    'Kinzah',
    'Félix Didolanvi',
    'Felix Didolanvi',
    'Arnauld Migan',
    'John Migan',
    'Kinivi',
    'Dossi',
    'Ange Ahouangonou',
  ],
  // ─── Nigéria ───
  // Verified (chart/streaming + editorial): Sinach, Nathaniel Bassey, Mercy
  // Chinwo, Dunsin Oyekan, Moses Bliss, Victor Thompson, Limoblaze, Tope
  // Alabi, Sunmisola Agbedi, Ada Ehi, Frank Edwards, Eben, Joe Praize, Buchi,
  // Sammie Okposo, Panam Percy Paul, Annatoria.
  'nigeria': [
    'Sinach',
    'Nathaniel Bassey',
    'Mercy Chinwo',
    'Dunsin Oyekan',
    'Moses Bliss',
    'Victor Thompson',
    'Limoblaze',
    'Tope Alabi',
    'Sunmisola Agbedi',
    'Ada Ehi',
    'Frank Edwards',
    'Eben',
    'Joe Praize',
    'Buchi',
    'Sammie Okposo',
    'Panam Percy Paul',
    'Annatoria',
  ],
  // ─── Ghana ───
  // Verified: Joe Mettle, Diana Hamilton, Celestine Donkor, Ohemaa Mercy,
  // Nacee, Joyce Blessing, Obaapa Christy, Diana Asamoah, Sonnie Badu, KODA,
  // Ceccy Twum, Daughters of Glorious Jesus, Tagoe Sisters, Yaw Sarpong,
  // Philipa Baafi.
  'ghana': [
    'Joe Mettle',
    'Diana Hamilton',
    'Celestine Donkor',
    'Ohemaa Mercy',
    'Nacee',
    'Joyce Blessing',
    'Obaapa Christy',
    'Diana Asamoah',
    'Sonnie Badu',
    'KODA',
    'Ceccy Twum',
    'Daughters of Glorious Jesus',
    'Tagoe Sisters',
    'Yaw Sarpong',
    'Philipa Baafi',
  ],
  // ─── Afrique du Sud ───
  'south africa': [
    'Rebecca Malope',
    'Lebo Sekgobela',
    'Lebo Sekgobela ',
    'Ntokozo Mbambo',
    'Sipho Makhabane',
    'Spirit Of Praise',
    'Xolly Mncwango',
  ],
  // ─── Kenya / East Africa ───
  'kenya': [
    'Daddy Owen',
    'Ruth Kome',
    'Mtimkavu ',
  ],
  // ─── USA / US Gospel ───
  // Verified mainstream US gospel & worship acts.
  'usa': [
    'Kirk Franklin',
    'Donnie McClurkin',
    'Tasha Cobbs',
    'Yolanda Adams',
    'CeCe Winans',
    'Hezekiah Walker',
    'Fred Hammond',
    'Marvin Sapp',
    'Jonathan McReynolds',
    'Travis Greene',
    'Maverick City Music',
    'Maverick City',
    'Bethel Music',
    'Elevation Worship',
    'Hillsong Worship',
    'Kierra Sheard',
    'Shirley Caesar',
    'Bishop Paul Morton',
  ],
  // ─── France / francophone ───
  // Verified francophone gospel / worship acts.
  'france': [
    'Glorious',
    'Angela Lartigue',
    'Fabrice Colson',
    'Matt Marvane',
    'Miri B',
    'Samuel Sesay',
    'Enock Tady',
    'Mattieu Semhoum',
    'Lex',
  ],
  // ─── Congo / Afrique centrale (via caribbean? no — own entry, mapped to
  // 'africa' region by detectGeo) ───
  // Central African gospel heavyweights that dominate francophone Africa.
  'africa': [
    'Mike Kalambay',
    'Dena Mwana',
    'Sandra Mbuyi',
    'Moise Mbiye',
    'Jonathan Yoyo',
    'Unis Par Le Sang',
    'Lydie Koffi',
  ],
};

const List<String> _regions = ['africa', 'west africa', 'east africa', 'caribbean'];

/// Geo keys that contain [geo] as a member (region containment). A region key
/// contains itself. Country keys contain only themselves.
bool _regionContains(String container, String member) {
  if (container == member) return true;
  switch (container) {
    case 'west africa':
      return const {'benin', 'nigeria', 'ghana'}.contains(member);
    case 'east africa':
      return const {'kenya'}.contains(member);
    case 'africa':
      return const {
        'benin',
        'nigeria',
        'ghana',
        'south africa',
        'kenya',
        'west africa',
        'east africa',
      }.contains(member);
    case 'caribbean':
      return const {'jamaica'}.contains(member);
    default:
      return false;
  }
}

/// Public wrapper used by [strict_category_filter].
bool regionContainsGeo(String container, String member) =>
    _regionContains(container, member);

/// Normalize an artist name for comparison: lowercase, fold accents, strip
/// common channel/suffix noise ("Officiel", "- Topic", "VEVO", ...).
String _artistNorm(String name) {
  return _norm(name)
      .replaceAll('officiel', ' ')
      .replaceAll('official', ' ')
      .replaceAll('official music video', ' ')
      .replaceAll('vevo', ' ')
      .replaceAll('topic', ' ')
      .replaceAll('kpoppop', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool _artistMatches(String primaryArtist, String curated) {
  final pn = _artistNorm(primaryArtist);
  final cn = _artistNorm(curated);
  if (pn.isEmpty || cn.isEmpty) return false;
  if (pn == cn) return true;
  // "Siano Bless Officiel" contains "siano bless"; curated names are always
  // the canonical short form, so substring both ways is safe here.
  if (pn.contains(cn)) return true;
  if (cn.length >= 4 && cn.contains(pn)) return true;
  return false;
}

/// True when [primaryArtist] is a confirmed gospel artist whose geo is inside
/// [geo] (directly or via a region, e.g. a Nigerian gospel artist inside the
/// "africa" region).
bool isGospelArtistIn(String primaryArtist, String geo) {
  final primary = primaryArtist.trim();
  if (primary.isEmpty) return false;
  for (final MapEntry(key: key, value: artists) in _gospelByGeo.entries) {
    if (!_regionContains(geo, key)) continue;
    for (final a in artists) {
      if (_artistMatches(primary, a)) return true;
    }
  }
  return false;
}

/// The geo a confirmed gospel artist belongs to, or null when the artist is
/// not a curated gospel artist. Used to reject a gospel artist of the *wrong*
/// country (e.g. Nigerian gospel inside "Benin Gospel").
String? gospelArtistGeo(String primaryArtist) {
  final primary = primaryArtist.trim();
  if (primary.isEmpty) return null;
  for (final MapEntry(key: key, value: artists) in _gospelByGeo.entries) {
    for (final a in artists) {
      if (_artistMatches(primary, a)) return key;
    }
  }
  return null;
}

/// First artist name from a `displayArtist` string (before "feat.", "&", ",").
String primaryArtistFrom(String displayArtist) {
  return displayArtist
      .split(RegExp(r'[,]| & | x | feat\.? | ft\.? '))
      .first
      .trim();
}
