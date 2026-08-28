/// Filtre global de contenu indien / Bollywood.
///
/// Objectif : aucun son indien ne doit apparaître dans l'app, sauf quand
/// l'utilisateur le demande explicitement (catégorie Desi : recherche par
/// terme Bollywood/Hindi/Punjabi ou par le nom exact d'un artiste indien).
library;

import 'package:muzo/models/muzo_item.dart';

/// Artistes / labels / chaînes indiens et pakistanais les plus répandus.
/// Matching par mots entiers uniquement : "King" ou "KK" sont volontairement
/// absents pour ne pas bloquer Kings of Leon, etc.
const Set<String> _indianNames = {
  // Playback / Bollywood
  'arijit singh', 'shreya ghoshal', 'sonu nigam', 'udit narayan',
  'kumar sanu', 'alka yagnik', 'lata mangeshkar', 'asha bhosle',
  'neha kakkar', 'tulsi kumar', 'armaan malik',
  'jubin nautiyal', 'darshan raval', 'sachet tandon', 'parampara tandon',
  'vishal dadlani', 'shekhar ravjiani', 'vishal shekhar', 'pritam',
  'shankar mahadevan', 'mohit chauhan',
  'sunidhi chauhan', 'shilpa rao', 'nakash aziz', 'benny dayal',
  'anirudh ravichander', 'sid sriram', 'dhanush', 'ilaiyaraaja',
  'ar rahman', 'allah rakha rahman',
  // Pop / hip-hop indien
  'badshah', 'nucleya', 'naezy', 'seedhe maut', 'prabh deep',
  'anuv jain', 'prateek kuhad', 'the local train', 'talwiinder',
  'jonita gandhi', 'lost stories', 'ritviz',
  // Punjabi
  'diljit dosanjh', 'ap dhillon', 'guru randhawa', 'yo yo honey singh',
  'honey singh', 'b praak', 'harrdy sandhu', 'ammy virk', 'jassie gill',
  'akhil', 'shubh', 'karan aujla', 'sidhu moose wala', 'amrit maan',
  'punjabi mc',
  // Pakistan (même univers musical)
  'atif aslam', 'rahat fateh ali khan', 'nusrat fateh ali khan',
  'ali zafar', 'shafqat amanat ali', 'abida parveen', 'kaavish',
  'coke studio',
  // Labels / chaînes
  't series', 'tseries', 'zee music', 'zee tv', 'saregama', 'goldmines',
  'wave music', 'tips official', 'yrf', 'eros now', 'jio studios',
  'dharma productions', '9xm', 'b4u', 'sony music india', 'mtv india',
  'junglee music', 'aditya music', 'lahari music', 'mango music',
  'speed records', 'white hill music', 'geet mp3',
};

/// Mots-clés forts et non ambigus du contenu indien (titre/artiste/chaîne).
final RegExp _indianKeywordRe = RegExp(
  r'\b(bollywood|kollywood|tollywood|lollywood|mollywood|hindi|punjabi|'
  r'desi|bhangra|ghazal|qawwali|bhajan|bhakti|indian pop)\b',
  caseSensitive: false,
);

String _norm(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), ' ').trim();

/// True si [normalized] contient un nom indien en mots entiers.
final Map<String, RegExp> _namePatternCache = {};
bool _nameHit(String normalized) {
  if (normalized.isEmpty) return false;
  for (final name in _indianNames) {
    final re = _namePatternCache.putIfAbsent(
      name,
      () => RegExp(r'\b' + RegExp.escape(name) + r'\b'),
    );
    if (re.hasMatch(normalized)) return true;
  }
  return false;
}

/// True si la requête elle-même demande explicitement du contenu indien
/// (terme Desi/Bollywood… ou nom d'artiste indien cherché volontairement).
bool queryAllowsIndianContent(String query) {
  final n = _norm(query);
  if (n.isEmpty) return false;
  const terms = [
    'desi', 'bollywood', 'hindi', 'punjabi', 'tamil', 'telugu',
    'malayalam', 'kannada', 'bhangra', 'indian', 'bhajan', 'ghazal',
  ];
  if (terms.any(n.contains)) return true;
  return _indianNames.contains(n);
}

/// True quand un titre est du contenu indien (artiste, label, chaîne ou
/// mot-clé reconnu). [contextQuery] permet l'exemption volontaire (Desi).
bool isIndianContent(MuzoItem song, {String contextQuery = ''}) {
  if (contextQuery.isNotEmpty && queryAllowsIndianContent(contextQuery)) {
    return false;
  }
  bool hit(String raw) {
    if (raw.isEmpty) return false;
    if (_indianKeywordRe.hasMatch(raw)) return true;
    return _nameHit(_norm(raw));
  }

  if (hit(song.title)) return true;
  if (hit(song.channelName ?? '')) return true;
  if (hit(song.album?.name ?? '')) return true;
  final artists = song.artists;
  if (artists != null) {
    for (final a in artists) {
      if (hit(a.name)) return true;
    }
  }
  return false;
}

/// Filtre une liste : retire tout contenu indien sauf exemption explicite.
List<MuzoItem> filterIndianContent(
  List<MuzoItem> items, {
  String contextQuery = '',
}) {
  if (contextQuery.isNotEmpty && queryAllowsIndianContent(contextQuery)) {
    return items;
  }
  return items.where((s) => !isIndianContent(s)).toList();}
