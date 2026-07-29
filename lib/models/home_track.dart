class HomeTrack {
  final String videoId;
  final String title;
  final String artist;
  final String duration;
  final String plays;
  final bool isFavorite;
  final String? imageUrl;

  const HomeTrack({
    required this.videoId,
    required this.title,
    required this.artist,
    required this.duration,
    this.plays = '',
    this.isFavorite = false,
    this.imageUrl,
  });
}

class HomeArtist {
  final String name;
  final String image;
  final String listeners;
  final String? imageUrl;

  const HomeArtist({
    required this.name,
    required this.image,
    this.listeners = '',
    this.imageUrl,
  });
}

class HomeAlbum {
  final String title;
  final String artist;
  final String image;
  final String year;
  final String? imageUrl;
  final int trackCount;
  final int? collectionId;
  final String? browseId;

  const HomeAlbum({
    required this.title,
    required this.artist,
    required this.image,
    this.year = '',
    this.imageUrl,
    this.trackCount = 0,
    this.collectionId,
    this.browseId,
  });
}

class HomeSection {
  final String title;
  final List<HomeTrack> tracks;
  final List<HomeArtist> artists;
  final List<HomeAlbum> albums;
  final HomeSectionType type;

  const HomeSection({
    required this.title,
    this.tracks = const [],
    this.artists = const [],
    this.albums = const [],
    this.type = HomeSectionType.tracks,
  });
}

enum HomeSectionType { tracks, artists, albums, mixed }
