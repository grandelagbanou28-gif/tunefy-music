/// Static, bundled artwork for every "Browse All" category.
///
/// The app no longer fetches category banners from the network — each category
/// ships with a real bundled cover so the banner is instant, offline-safe and
/// always on-brand. The map is keyed by the category `query` (lowercase) with
/// the display `title` as a fallback key.
library;

const String _covers = "assets/covers/";
const String _home = "assets/spotify/home/";
const String _spotify = "assets/spotify/";

/// query (lowercase) -> bundled asset path.
const Map<String, String> _assetsByQuery = {
  "pop": "${_covers}pop.jpg",
  "hip hop": "${_covers}hiphop.jpg",
  "rock": "${_covers}rock.jpg",
  "r&b": "${_covers}rnb.jpg",
  "latin": "${_covers}latin.jpg",
  "country": "${_covers}country.jpg",
  "jazz": "${_covers}jazz.jpg",
  "classical": "${_covers}classical.jpg",
  "electronic": "${_spotify}home/UTOPIA.jpg",
  "reggae": "${_covers}reggae.jpg",
  "blues": "${_covers}soul.jpg",
  "metal": "${_covers}rock.jpg",
  "folk acoustic": "${_spotify}home/AUSTIN.jpg",
  "soul": "${_covers}soul.jpg",
  "funk": "${_spotify}home/Offset-Mix.jpg",
  "gospel": "${_covers}soul.jpg",
  "rap": "${_covers}rap.jpg",
  "k-pop": "${_spotify}indie_pop.png",
  "indie": "${_spotify}indie.png",
  "afro hits": "${_covers}afro.jpg",
  "afrobeats": "${_covers}afro.jpg",
  "caribbean": "${_covers}reggae.jpg",
  "desi hits": "${_covers}hiphop.jpg",
  "house music": "${_spotify}home/roadtrip_playlist.png",
  "lofi beats": "${_spotify}home/shazam_playlist.png",
  "party": "${_spotify}home/Upbeat-Mix.jpg",
  "dance": "${_spotify}home/Upbeat-Mix.jpg",
  "romantic love songs": "${_spotify}liked_songs.png",
  "love": "${_spotify}liked_songs.png",
  "workout": "${_spotify}home/Rap-Workout.jpg",
  "focus": "${_spotify}study_playlist.png",
  "sleep": "${_home}chill-mix.png",
  "meditation": "${_home}chill-mix.png",
  "comedy": "${_spotify}comedy.png",
  "news": "${_spotify}news&politics.png",
  "podcast": "${_spotify}podcasts.png",
  "podcasts": "${_spotify}podcasts.png",
  "chill mood": "${_home}chill-mix.png",
  "mood": "${_home}chill-mix.png",
  "chill": "${_home}Daily-Mix-1.jpg",
  "oldies": "${_home}2010s-mix.png",
  "new release": "${_spotify}new_episods.png",
  "new releases": "${_spotify}new_episods.png",
  "top hits": "${_spotify}charts.png",
  "chill mix": "${_spotify}made_for_you.png",
  "live": "${_spotify}2023_wrapped.png",
  "benin hits": "${_covers}benin.jpg",
  "amapiano": "${_spotify}2023_wrapped.png",
  "bande originale": "${_spotify}study_playlist.png",
  "dancehall": "${_spotify}song_screen_big.png",
  "musique arabe": "${_home}Drake-Mix.jpg",
  "rumba congolaise": "${_spotify}myImage.png",
  "drill": "${_spotify}indie.png",
  "rap francais": "${_covers}rapfr.jpg",
  "chanson francaise": "${_covers}chanson.jpg",
  "new artists": "${_home}Drake-Mix.jpg",
  "hit benin": "${_covers}benin.jpg",
};

/// Display title (lowercase) -> bundled asset path.
const Map<String, String> _assetsByTitle = {
  "pop": "${_covers}pop.jpg",
  "hip-hop": "${_covers}hiphop.jpg",
  "rock": "${_covers}rock.jpg",
  "r&b": "${_covers}rnb.jpg",
  "latin": "${_covers}latin.jpg",
  "country": "${_covers}country.jpg",
  "jazz": "${_covers}jazz.jpg",
  "classical": "${_covers}classical.jpg",
  "electronic": "${_spotify}home/UTOPIA.jpg",
  "reggae": "${_covers}reggae.jpg",
  "soul": "${_covers}soul.jpg",
  "funk": "${_spotify}home/Offset-Mix.jpg",
  "gospel": "${_covers}soul.jpg",
  "rap": "${_covers}rap.jpg",
  "k-pop": "${_spotify}indie_pop.png",
  "indie": "${_spotify}indie.png",
  "afro hits": "${_covers}afro.jpg",
  "afrobeats": "${_covers}afro.jpg",
  "caribbean": "${_covers}reggae.jpg",
  "desi": "${_covers}hiphop.jpg",
  "house": "${_spotify}home/roadtrip_playlist.png",
  "lo-fi beats": "${_spotify}home/shazam_playlist.png",
  "party": "${_spotify}home/Upbeat-Mix.jpg",
  "romance": "${_spotify}liked_songs.png",
  "workout": "${_spotify}home/Rap-Workout.jpg",
  "focus": "${_spotify}study_playlist.png",
  "sleep": "${_home}chill-mix.png",
  "meditation": "${_home}chill-mix.png",
  "comedy": "${_spotify}comedy.png",
  "news & politics": "${_spotify}news&politics.png",
  "podcasts": "${_spotify}podcasts.png",
  "mood": "${_home}chill-mix.png",
  "chill": "${_home}Daily-Mix-1.jpg",
  "decades": "${_home}2010s-mix.png",
  "new releases": "${_spotify}new_episods.png",
  "charts": "${_spotify}charts.png",
  "made for you": "${_spotify}made_for_you.png",
  "trending": "${_spotify}charts.png",
  "hit benin": "${_covers}benin.jpg",
  "amapiano": "${_spotify}2023_wrapped.png",
  "bande originale": "${_spotify}study_playlist.png",
  "dancehall": "${_spotify}song_screen_big.png",
  "musique arabe": "${_home}Drake-Mix.jpg",
  "rumba congolaise": "${_spotify}myImage.png",
  "drill": "${_spotify}indie.png",
  "rap fran\u00e7ais": "${_covers}rapfr.jpg",
  "chansons": "${_covers}chanson.jpg",
  "blues": "${_covers}soul.jpg",
  "metal": "${_covers}rock.jpg",
  "folk & acoustic": "${_spotify}home/AUSTIN.jpg",
};

/// Returns the bundled asset path for a category, or null if none matches.
String? categoryAsset(String query, String title) {
  final q = query.trim().toLowerCase();
  if (q.isNotEmpty && _assetsByQuery.containsKey(q)) return _assetsByQuery[q];
  final t = title.trim().toLowerCase();
  if (t.isNotEmpty && _assetsByTitle.containsKey(t)) return _assetsByTitle[t];
  return null;
}