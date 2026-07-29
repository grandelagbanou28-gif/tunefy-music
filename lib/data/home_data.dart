import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tunefy/models/home_track.dart';
import 'package:tunefy/services/itunes_service.dart';
import 'package:tunefy/services/search_service.dart';
import 'package:tunefy/services/liked_service.dart';
import 'package:tunefy/services/premium_service.dart';
import 'package:tunefy/services/muzo_service.dart';
import 'package:tunefy/services/music_catalog_service.dart';

class HomeData {
  HomeData._();

  static List<HomeSection> sections = [];
  static bool _loaded = false;
  static VoidCallback? onSectionsUpdated;

  /// Indices des sections réservées Premium (dans l'ordre de sections[])
  static const _premiumOnly = {6, 7, 8, 9, 10, 14, 15, 16, 18, 19, 20, 21, 24};

  /// Sections visibles selon l'abonnement
  static List<HomeSection> get visibleSections {
    if (PremiumService.isPremium) return sections;
    return [
      for (var i = 0; i < sections.length; i++)
        if (!_premiumOnly.contains(i)) sections[i],
    ];
  }
  static bool _loading = false;
  static bool _refreshing = false;
  static Timer? _refreshTimer;
  static const int _refreshHour = 6;

  static Future<void> load() async {
    if (_loaded || _loading) {
      return;
    }
    _loaded = true;
    _loading = true;
    debugPrint('HomeData: load() started');

    // Charge les données iTunes directement
    try {
      await _refreshFromCharts().timeout(const Duration(seconds: 45));
    } catch (_) {
      debugPrint('HomeData: initial chart refresh failed, using static fallback');
      _loadStaticSections();
    }
    _startRefreshTimer();
    _loading = false;
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_refreshing) return;
      final now = DateTime.now();
      if (now.hour != _refreshHour) return;
      final settings = Hive.box('settings');
      final lastRefresh = settings.get('lastRefreshDate');
      if (lastRefresh != null &&
          _isSameDay(
              DateTime.fromMillisecondsSinceEpoch(lastRefresh as int), now)) {
        return;
      }
      _refreshing = true;
      try {
        await _refreshFromCharts().timeout(const Duration(seconds: 30));
        await settings.put('lastRefreshDate', now.millisecondsSinceEpoch);
      } catch (_) {
        debugPrint('HomeData: timer refresh failed');
      } finally {
        _refreshing = false;
      }
    });
  }

  static Future<void> _refreshFromCharts() async {
    if (_refreshing) return;
    _refreshing = true;
    debugPrint('HomeData: _refreshFromCharts started');
    try {
      final y = DateTime.now().year;

      // Batch 1: artists & albums (iTunes + Catalog) — 2026 uniquement
      final r1 = await Future.wait([
        ItunesService.fetchChartArtists(limit: 25),
        ItunesService.fetchChartAlbums(limit: 25),
        MusicCatalogService.searchAlbums('popular', limit: 15),
        MusicCatalogService.searchAlbums('trending', limit: 15),
        MuzoService.searchAlbumsByGenre('popular', limit: 10),
      ]).timeout(const Duration(seconds: 30));
      final artists = r1[0] as List<HomeArtist>;
      final albums = <HomeAlbum>[
        ...(r1[1] as List<HomeAlbum>),
        ...(r1[2] as List<CatalogAlbum>).map(_catToHomeAlbum),
        ...(r1[3] as List<CatalogAlbum>).map(_catToHomeAlbum),
        ...(r1[4] as List<HomeAlbum>),
      ]..retainWhere((a) => a.year == '2026');
      final seen = <String>{};
      albums.retainWhere((a) => seen.add(a.title.toLowerCase()));

      // Batch 2: genres (utilisés pour le global + sections spécifiques)
      final r2 = await Future.wait([
        ItunesService.searchTracksByQuery('rap hip hop $y', limit: 50),
        ItunesService.searchTracksByQuery('pop $y', limit: 50),
        ItunesService.searchTracksByQuery('afrobeat $y', limit: 50),
        ItunesService.searchTracksByQuery('dance $y', limit: 30),
        ItunesService.searchTracksByQuery('drill', limit: 30),
      ]).timeout(const Duration(seconds: 30));
      final rap = r2[0] as List<HomeTrack>;
      final pop = r2[1] as List<HomeTrack>;
      final afro = r2[2] as List<HomeTrack>;
      final dance = r2[3] as List<HomeTrack>;
      final drill = r2[4] as List<HomeTrack>;

      // Batch 3: more genres + search
      final r3 = await Future.wait([
        ItunesService.searchTracksByQuery('afro drill', limit: 30),
        ItunesService.searchTracksByQuery('uk drill $y', limit: 20),
        ItunesService.searchTracksByQuery('new music $y', limit: 30),
        ItunesService.searchTracksByQuery('upcoming $y', limit: 30),
      ]).timeout(const Duration(seconds: 30));
      final afroDrill = r3[0] as List<HomeTrack>;
      final nuevas = r3[2] as List<HomeTrack>;
      final decouvertes = r3[3] as List<HomeTrack>;

      // Global = merge de tous les genres pour des artworks variés
      final global = <HomeTrack>[
        ...rap, ...pop, ...afro, ...dance, ...drill,
        ...afroDrill, ...nuevas, ...decouvertes,
      ]..shuffle(Random());

      // Batch 4: artist top tracks (2 at a time)
      final rapFR = <HomeTrack>[];
      final artistNames = ['Gims', 'Ninho', 'Jul', 'SCH', 'Gazo', 'Damso', 'Booba', 'Niska'];
      for (var i = 0; i < artistNames.length; i += 2) {
        final batch = artistNames.sublist(i, (i + 2).clamp(0, artistNames.length));
        final results = await Future.wait(batch.map((a) => ItunesService.fetchArtistTopTracks(a)));
        for (final tracks in results) rapFR.addAll(tracks);
      }
      rapFR.shuffle(Random());

      // Batch 5: podcasts
      List<HomeTrack> podcasts = [];
      try {
        podcasts = await ItunesService.fetchPodcasts(limit: 20);
      } catch (_) {}
      podcasts.shuffle(Random());

      // Batch 6: nouveaux albums = rap FR + US uniquement
      List<HomeAlbum> rapFRalbums = [], rapUSalbums = [], catNew = [];
      try {
        final r6 = await Future.wait([
          ItunesService.fetchAlbumsByGenre('rap français', limit: 10),
          ItunesService.fetchAlbumsByGenre('rap us', limit: 10),
          MusicCatalogService.searchAlbums('rap francais nouveau', limit: 10),
          MusicCatalogService.searchAlbums('rap us new', limit: 10),
        ]).timeout(const Duration(seconds: 30));
        rapFRalbums = r6[0] as List<HomeAlbum>;
        rapUSalbums = r6[1] as List<HomeAlbum>;
        catNew = ((r6[2] as List<CatalogAlbum>)
                ..addAll(r6[3] as List<CatalogAlbum>))
            .where((a) => a.artist.toLowerCase().contains('rap'))
            .map(_catToHomeAlbum).toList();
      } catch (_) {}
      final newAlbums = <HomeAlbum>[...rapFRalbums, ...rapUSalbums, ...catNew]
        ..shuffle(Random());
      final seen2 = <String>{};
       final newAlbumsFiltered = newAlbums.where((a) => seen2.add(a.title.toLowerCase()) && a.year == '2026').toList();

      final rapWorld = [...rap, ...rapFR.take(30), ...afro.take(15)]..shuffle(Random());
      final drillWorld = [...drill, ...rapFR.take(10), ...afro.take(10)]..shuffle(Random());
      final dancePopWorld = [...dance, ...pop]..shuffle(Random());
      final afroDrillWorld = [...afroDrill, ...drill.take(10), ...afro.take(10)]..shuffle(Random());

    List<HomeTrack> _slice(List<HomeTrack> list, int start, int count) {
      if (start >= list.length) return [];
      return list.sublist(start, min(start + count, list.length));
    }

    // Parce que vous avez écouté → recherche iTunes basée sur les artistes du chart
    var parceQueVous = _slice(global, 60, 10);
    try {
      final seedArtists = global
          .take(10)
          .map((t) => t.artist)
          .where((n) => n.isNotEmpty)
          .toSet()
          .take(3)
          .toList();
      final artistFutures =
          seedArtists.map((a) => ItunesService.fetchArtistTopTracks(a));
      final artistResults = await Future.wait(artistFutures);
      final merged = <HomeTrack>[];
      for (final t in artistResults) {
        merged.addAll(t);
      }
      merged.shuffle(Random());
      if (merged.length >= 5) parceQueVous = merged;
    } catch (_) {}

    // Vos chansons préférées → LikedService
    var vosChansons = _slice(global, 50, 10);
    try {
      final liked = LikedService().getAll();
      if (liked.isNotEmpty) {
        vosChansons = liked
            .map((t) => HomeTrack(
                  videoId: t.videoId ?? '',
                  title: t.title,
                  artist: t.artist,
                  duration: t.duration != null
                      ? '${t.duration!.inMinutes}:${(t.duration!.inSeconds % 60).toString().padLeft(2, '0')}'
                      : '',
                  imageUrl: t.albumImage,
                ))
            .toList()
          ..shuffle(Random());
        vosChansons = vosChansons.take(10).toList();
      }
    } catch (_) {}

    // Plus à découvrir → Deezer search "upcoming $y"
    var plusADecouvrir = _slice(global, 70, 10);
    try {
      final discover =
          await ItunesService.searchTracksByQuery('upcoming $y', limit: 30);
      if (discover.length >= 5) plusADecouvrir = discover;
    } catch (_) {}

    // Vos artistes préférés → extraits des liked songs
    var vosArtistes = artists.skip(10).take(10).toList();
    try {
      final liked = LikedService().getAll();
      if (liked.isNotEmpty) {
        final seen = <String>{};
        final fromLiked = <HomeArtist>[];
        for (final t in liked) {
          if (t.artist.isEmpty || !seen.add(t.artist)) continue;
          var imgUrl = t.artistImage;
          if (imgUrl == null || imgUrl.isEmpty) {
            imgUrl = await ItunesService.fetchArtistImage(t.artist);
          }
          fromLiked.add(HomeArtist(name: t.artist, image: '', listeners: '', imageUrl: imgUrl));
        }
        fromLiked.shuffle(Random());
        if (fromLiked.length >= 3) vosArtistes = fromLiked.take(10).toList();
      }
    } catch (_) {}

    sections = [
      _ts("Continuer l'écoute", _slice(global, 10, 10)),
      _ts('Créé pour vous', _slice(global, 20, 10)),
      _ts('Mix Quotidien', _slice(global, 30, 10)),
      _ts('Nouvelles sorties', _slice(nuevas, 0, 10)),
      _ts('Découvertes de la semaine', _slice(decouvertes, 0, 10)),
       _als('Nouveaux albums', newAlbumsFiltered.take(10).toList()),
      _als('Albums populaires', albums.take(25).toList()),
      _ts('Mix Drill', _slice(drillWorld, 0, 10)),
      _ts('Mix Trap', _slice(rapWorld, 0, 10)),
      _ts('Rap Français', rapFR.take(12).toList()),
      _ts('Rap International', _slice(rapWorld, 10, 12)),
      _ts('Rap Africain', _slice(afro, 0, 10)),
      _as('Artistes populaires', artists.take(10).toList()),
      _ts('Chansons tendance', _slice(global, 40, 10)),
      _ts('Top 50 Rap Monde', _slice(rapWorld, 20, 12)),
      _ts('Parce que vous avez écouté', parceQueVous.take(10).toList()),
      _as('Vos artistes préférés', vosArtistes.take(10).toList()),
      _ts('Vos chansons préférées', vosChansons.take(10).toList()),
      _ts('Afro Drill', _slice(afroDrillWorld, 0, 10)),
      _ts('Plus à découvrir', plusADecouvrir.take(10).toList()),
      _ts('Classiques du Rap', _slice(rapWorld, 30, 10)),
      _ts('Tendances Rap FR', rapFR.skip(12).take(10).toList()),
      _ts('Dance & Pop', _slice(dancePopWorld, 0, 10)),
      _ts('Afrobeats', _slice(afro, 10, 10)),
      _ts('Drill World', _slice(drillWorld, 10, 10)),
      _ts('Podcasts populaires', podcasts.take(10).toList()),
    ];
    final seenArtists = <String>{};
    for (final sec in sections) {
      if (sec.type != HomeSectionType.tracks) continue;
      final filtered = <HomeTrack>[];
      for (final t in sec.tracks) {
        final key = t.artist.toLowerCase().trim();
        if (key.isEmpty || seenArtists.add(key)) filtered.add(t);
      }
      sections[sections.indexOf(sec)] = HomeSection(title: sec.title, type: sec.type, tracks: filtered);
    }
    sections.removeWhere((s) =>
        (s.type == HomeSectionType.tracks && s.tracks.isEmpty) ||
        (s.type == HomeSectionType.artists && s.artists.isEmpty) ||
        (s.type == HomeSectionType.albums && s.albums.isEmpty));
    debugPrint('HomeData: _refreshFromCharts finished, ${sections.length} sections, ${sections.fold<int>(0, (s, sec) => s + sec.tracks.length)} total tracks');
    } catch (e) {
      debugPrint('HomeData: _refreshFromCharts error: $e');
      rethrow;
    } finally {
      _refreshing = false;
    }
  }

  static HomeSection _ts(String title, List<HomeTrack> tracks) =>
      HomeSection(title: title, type: HomeSectionType.tracks, tracks: tracks);
  static HomeSection _as(String title, List<HomeArtist> artists) =>
      HomeSection(title: title, type: HomeSectionType.artists, artists: artists);
  static HomeSection _als(String title, List<HomeAlbum> albums) =>
      HomeSection(title: title, type: HomeSectionType.albums, albums: albums);

  static HomeAlbum _catToHomeAlbum(CatalogAlbum ca) => HomeAlbum(
    title: ca.title,
    artist: ca.artist,
    image: ca.imageUrl ?? '',
    imageUrl: ca.imageUrl,
    trackCount: ca.trackCount,
    browseId: ca.id,
  );

  static List<HomeTrack> _searchResultsToTracks(List<SearchResult> results) {
    return results.map((r) {
      final videoId = r.videoId ??
          (r.saavnId != null ? 'deezer_${r.saavnId}' : r.id);
      return HomeTrack(
        videoId: videoId,
        title: r.title,
        artist: r.subtitle,
        duration: r.duration ?? '',
        imageUrl: r.imageUrl,
      );
    }).toList();
  }

  static void _loadStaticSections() {
    sections = [
      _continuerEcoute,
      _creePourVous,
      _mixQuotidien,
       _nouvellesSorties,
       _decouvertesSemaine,
      _mixDrill,
      _mixTrap,
       _rapFrancais,
       _rapUSUK,
       _rapAfricain,
       _artistesPopulaires,
      _chansonsTendance,
      _top50RapMonde,
      _parceQueVousAvez,
      _vosArtistesPref,
      _vosChansonsPref,
      _afroDrill,
      _plusADecouvrir,
      _classiquesRap,
      _tendancesRapFR,
      _dancePop,
      _afrobeats,
      _drillWorld,
      _podcastsSection,
    ];
  }

  static const _ecoutesRecemment = HomeSection(
    title: 'Écoutés récemment',
    type: HomeSectionType.tracks,
    tracks: [
      HomeTrack(videoId: 'ko70cExuzZM', title: 'The Fate of Ophelia', artist: 'Taylor Swift', duration: '4:12', plays: '359M'),
      HomeTrack(videoId: 'mrV8kK5t0V8', title: 'I Just Might', artist: 'Bruno Mars', duration: '3:45', plays: '129M'),
      HomeTrack(videoId: 'lY5V4hSLWY8', title: 'Risk It All', artist: 'Bruno Mars', duration: '3:28', plays: '76M'),
      HomeTrack(videoId: '7sxVHYZ_PnA', title: 'Aperture', artist: 'Harry Styles', duration: '3:50', plays: '28M'),
      HomeTrack(videoId: 'hUbm0IpeNuk', title: 'Man I Need', artist: 'Olivia Dean', duration: '3:35', plays: '113M'),
      HomeTrack(videoId: 'rK5TyISxZ_M', title: 'WHERE IS MY HUSBAND!', artist: 'RAYE', duration: '2:45', plays: '19M'),
      HomeTrack(videoId: 'SOJpE1KMUbo', title: 'Raindance', artist: 'Dave', duration: '3:40', plays: '156M'),
      HomeTrack(videoId: 'lIxQe1R5hs0', title: 'Stateside', artist: 'PinkPantheress & Zara Larsson', duration: '3:15', plays: '64M'),
      HomeTrack(videoId: '3triLkS0nq4', title: 'Rein Me In', artist: 'Sam Fender & Olivia Dean', duration: '4:20', plays: '13M'),
      HomeTrack(videoId: 'u2ah9tWTkmk', title: 'Ordinary', artist: 'Alex Warren', duration: '3:30', plays: '336M'),
    ],
  );

  static const _continuerEcoute = HomeSection(
    title: 'Continuer l\'écoute',
    type: HomeSectionType.tracks,
    tracks: [
      HomeTrack(videoId: 'aSugSGCC12I', title: 'Manchild', artist: 'Sabrina Carpenter', duration: '3:18', plays: '476M'),
      HomeTrack(videoId: 'V9vuCByb6js', title: 'Tears', artist: 'Sabrina Carpenter', duration: '3:45', plays: '48M'),
      HomeTrack(videoId: 'eVli-tstM5E', title: 'Espresso', artist: 'Sabrina Carpenter', duration: '3:07', plays: '2.1B'),
      HomeTrack(videoId: 'kPa7bsKwL-c', title: 'Die With A Smile', artist: 'Lady Gaga & Bruno Mars', duration: '4:11', plays: '3.1B'),
      HomeTrack(videoId: 'ekr2nIex040', title: 'APT.', artist: 'ROSÉ & Bruno Mars', duration: '3:15', plays: '2.7B'),
      HomeTrack(videoId: 'V9PVRfjEBTI', title: 'BIRDS OF A FEATHER', artist: 'Billie Eilish', duration: '3:42', plays: '1.5B'),
      HomeTrack(videoId: 'Oa_RSwwpPaA', title: 'Beautiful Things', artist: 'Benson Boone', duration: '3:30', plays: '2.6B'),
      HomeTrack(videoId: '0U_7gdlR5I0', title: 'Lose Control', artist: 'Teddy Swims', duration: '3:40', plays: '650M'),
      HomeTrack(videoId: '1RKqOmSkGgM', title: 'Good Luck, Babe!', artist: 'Chappell Roan', duration: '3:48', plays: '148M'),
      HomeTrack(videoId: 'BDHM8cyJQa8', title: 'That\'s So True', artist: 'Gracie Abrams', duration: '2:48', plays: '234M'),
    ],
  );

  static const _creePourVous = HomeSection(
    title: 'Créé pour vous',
    type: HomeSectionType.tracks,
    tracks: [
      HomeTrack(videoId: 'Tw08lNebAjE', title: 'DtMF', artist: 'Bad Bunny', duration: '3:12', plays: '175M'),
      HomeTrack(videoId: 'uLK2r3sG4lE', title: 'PUSH 2 START', artist: 'Tyla', duration: '3:25', plays: '153M'),
      HomeTrack(videoId: 'JgDNFQ2RaLQ', title: 'Sapphire', artist: 'Ed Sheeran', duration: '3:50', plays: '189M'),
      HomeTrack(videoId: 'DubtPdXXjew', title: 'The Giver', artist: 'Chappell Roan', duration: '3:18', plays: '42M'),
      HomeTrack(videoId: 'TiMuT2BhwO0', title: 'Risk', artist: 'Gracie Abrams', duration: '3:15', plays: '18M'),
      HomeTrack(videoId: 'Z3aduh5fxCo', title: 'Show Me Love', artist: 'WizTheMc', duration: '3:10', plays: '716M'),
      HomeTrack(videoId: '4QIZE708gJ4', title: 'I Had Some Help', artist: 'Post Malone & Morgan Wallen', duration: '3:30', plays: '236M'),
      HomeTrack(videoId: 'ecVKhR5cnGg', title: 'Lovin On Me', artist: 'Jack Harlow', duration: '3:25', plays: '227M'),
      HomeTrack(videoId: 'ZjBZ8MUnB0E', title: 'Training Season', artist: 'Dua Lipa', duration: '3:30', plays: '87M'),
      HomeTrack(videoId: 'dIQlZvPI_ac', title: 'Gata Only', artist: 'FloyyMenor & Cris MJ', duration: '3:00', plays: '1.1B'),
    ],
  );

  static const _mixQuotidien = HomeSection(
    title: 'Mix Quotidien',
    type: HomeSectionType.tracks,
    tracks: [
      HomeTrack(videoId: 'ko70cExuzZM', title: 'The Fate of Ophelia', artist: 'Taylor Swift', duration: '4:12', plays: '359M'),
      HomeTrack(videoId: 'mrV8kK5t0V8', title: 'I Just Might', artist: 'Bruno Mars', duration: '3:45', plays: '129M'),
      HomeTrack(videoId: '7sxVHYZ_PnA', title: 'Aperture', artist: 'Harry Styles', duration: '3:50', plays: '28M'),
      HomeTrack(videoId: 'hUbm0IpeNuk', title: 'Man I Need', artist: 'Olivia Dean', duration: '3:35', plays: '113M'),
      HomeTrack(videoId: 'SOJpE1KMUbo', title: 'Raindance', artist: 'Dave', duration: '3:40', plays: '156M'),
      HomeTrack(videoId: 'lIxQe1R5hs0', title: 'Stateside', artist: 'PinkPantheress & Zara Larsson', duration: '3:15', plays: '64M'),
      HomeTrack(videoId: 'u2ah9tWTkmk', title: 'Ordinary', artist: 'Alex Warren', duration: '3:30', plays: '336M'),
      HomeTrack(videoId: 'aSugSGCC12I', title: 'Manchild', artist: 'Sabrina Carpenter', duration: '3:18', plays: '476M'),
      HomeTrack(videoId: 'kPa7bsKwL-c', title: 'Die With A Smile', artist: 'Lady Gaga & Bruno Mars', duration: '4:11', plays: '3.1B'),
      HomeTrack(videoId: 'ekr2nIex040', title: 'APT.', artist: 'ROSÉ & Bruno Mars', duration: '3:15', plays: '2.7B'),
    ],
  );

  static const _mixDrill = HomeSection(
    title: 'Mix Drill',
    type: HomeSectionType.tracks,
    tracks: [
      HomeTrack(videoId: 'Tw08lNebAjE', title: 'DtMF', artist: 'Bad Bunny', duration: '3:12', plays: '175M'),
      HomeTrack(videoId: 'uLK2r3sG4lE', title: 'PUSH 2 START', artist: 'Tyla', duration: '3:25', plays: '153M'),
      HomeTrack(videoId: 'dIQlZvPI_ac', title: 'Gata Only', artist: 'FloyyMenor & Cris MJ', duration: '3:00', plays: '1.1B'),
      HomeTrack(videoId: 'SOJpE1KMUbo', title: 'Raindance', artist: 'Dave', duration: '3:40', plays: '156M'),
      HomeTrack(videoId: 'lIxQe1R5hs0', title: 'Stateside', artist: 'PinkPantheress & Zara Larsson', duration: '3:15', plays: '64M'),
      HomeTrack(videoId: 'u2ah9tWTkmk', title: 'Ordinary', artist: 'Alex Warren', duration: '3:30', plays: '336M'),
      HomeTrack(videoId: 'aSugSGCC12I', title: 'Manchild', artist: 'Sabrina Carpenter', duration: '3:18', plays: '476M'),
      HomeTrack(videoId: 'rK5TyISxZ_M', title: 'WHERE IS MY HUSBAND!', artist: 'RAYE', duration: '2:45', plays: '19M'),
      HomeTrack(videoId: '3triLkS0nq4', title: 'Rein Me In', artist: 'Sam Fender & Olivia Dean', duration: '4:20', plays: '13M'),
      HomeTrack(videoId: 'BDHM8cyJQa8', title: 'That\'s So True', artist: 'Gracie Abrams', duration: '2:48', plays: '234M'),
    ],
  );

  static const _mixTrap = HomeSection(
    title: 'Mix Trap',
    type: HomeSectionType.tracks,
    tracks: [
      HomeTrack(videoId: 'Tw08lNebAjE', title: 'DtMF', artist: 'Bad Bunny', duration: '3:12', plays: '175M'),
      HomeTrack(videoId: 'uLK2r3sG4lE', title: 'PUSH 2 START', artist: 'Tyla', duration: '3:25', plays: '153M'),
      HomeTrack(videoId: '4QIZE708gJ4', title: 'I Had Some Help', artist: 'Post Malone & Morgan Wallen', duration: '3:30', plays: '236M'),
      HomeTrack(videoId: 'ecVKhR5cnGg', title: 'Lovin On Me', artist: 'Jack Harlow', duration: '3:25', plays: '227M'),
      HomeTrack(videoId: 'dIQlZvPI_ac', title: 'Gata Only', artist: 'FloyyMenor & Cris MJ', duration: '3:00', plays: '1.1B'),
      HomeTrack(videoId: 'u2ah9tWTkmk', title: 'Ordinary', artist: 'Alex Warren', duration: '3:30', plays: '336M'),
      HomeTrack(videoId: 'aSugSGCC12I', title: 'Manchild', artist: 'Sabrina Carpenter', duration: '3:18', plays: '476M'),
      HomeTrack(videoId: 'kPa7bsKwL-c', title: 'Die With A Smile', artist: 'Lady Gaga & Bruno Mars', duration: '4:11', plays: '3.1B'),
      HomeTrack(videoId: 'ekr2nIex040', title: 'APT.', artist: 'ROSÉ & Bruno Mars', duration: '3:15', plays: '2.7B'),
      HomeTrack(videoId: 'V9PVRfjEBTI', title: 'BIRDS OF A FEATHER', artist: 'Billie Eilish', duration: '3:42', plays: '1.5B'),
    ],
  );

  static const _rapFrancais = HomeSection(
    title: 'Rap Français',
    type: HomeSectionType.tracks,
    tracks: [
      HomeTrack(videoId: '2y3aXDFDcck', title: 'Puissance', artist: 'Gims', duration: '3:15', plays: '423M'),
      HomeTrack(videoId: 'XWGwCgvYUBc', title: 'Freestyle LVL UP 3', artist: 'Ninho', duration: '3:22', plays: '201M'),
      HomeTrack(videoId: 'vRgOX5SdQp8', title: 'Filtré', artist: 'Gazo & Timal', duration: '2:45', plays: '156M'),
      HomeTrack(videoId: '-CVn3-3g_BI', title: 'Bande organisée', artist: 'SCH & Jul', duration: '3:45', plays: '487M'),
      HomeTrack(videoId: 'Zck0zkv67gs', title: 'Badman Gangsta', artist: 'Tiakola & Asake', duration: '3:10', plays: '312M'),
      HomeTrack(videoId: 'FEx-1mEZvYo', title: 'Freestyle', artist: 'Werenoi', duration: '3:12', plays: '89M'),
      HomeTrack(videoId: 'UI6MNEduTL8', title: 'Train Mistral', artist: 'SCH', duration: '3:05', plays: '134M'),
      HomeTrack(videoId: 'dPM9wfRtErM', title: 'La Rue', artist: 'No Limit & Gazo & Damso', duration: '2:40', plays: '98M'),
      HomeTrack(videoId: 'eOolBt4GgIE', title: 'Amour X Lyric', artist: 'Niska', duration: '2:51', plays: '178M'),
      HomeTrack(videoId: 'KpWGeu2QOgQ', title: 'Tout oublier', artist: 'Damso', duration: '4:15', plays: '245M'),
      HomeTrack(videoId: 'wvLv_Pem0BA', title: "C'est la vie", artist: 'Booba', duration: '3:02', plays: '198M'),
      HomeTrack(videoId: 'xX4Pxiwti4E', title: 'Zoo', artist: 'Kaaris', duration: '2:48', plays: '89M'),
      HomeTrack(videoId: 'IDJJWXJmA7k', title: 'Money', artist: 'Hamza', duration: '3:15', plays: '78M'),
    ],
  );

  static const _rapUSUK = HomeSection(
    title: 'Rap US / UK',
    type: HomeSectionType.tracks,
    tracks: [
      HomeTrack(videoId: 'Tw08lNebAjE', title: 'DtMF', artist: 'Bad Bunny', duration: '3:12', plays: '175M'),
      HomeTrack(videoId: '4QIZE708gJ4', title: 'I Had Some Help', artist: 'Post Malone & Morgan Wallen', duration: '3:30', plays: '236M'),
      HomeTrack(videoId: 'ecVKhR5cnGg', title: 'Lovin On Me', artist: 'Jack Harlow', duration: '3:25', plays: '227M'),
      HomeTrack(videoId: 'dIQlZvPI_ac', title: 'Gata Only', artist: 'FloyyMenor & Cris MJ', duration: '3:00', plays: '1.1B'),
      HomeTrack(videoId: 'uLK2r3sG4lE', title: 'PUSH 2 START', artist: 'Tyla', duration: '3:25', plays: '153M'),
      HomeTrack(videoId: 'u2ah9tWTkmk', title: 'Ordinary', artist: 'Alex Warren', duration: '3:30', plays: '336M'),
      HomeTrack(videoId: 'aSugSGCC12I', title: 'Manchild', artist: 'Sabrina Carpenter', duration: '3:18', plays: '476M'),
      HomeTrack(videoId: 'kPa7bsKwL-c', title: 'Die With A Smile', artist: 'Lady Gaga & Bruno Mars', duration: '4:11', plays: '3.1B'),
      HomeTrack(videoId: 'ekr2nIex040', title: 'APT.', artist: 'ROSÉ & Bruno Mars', duration: '3:15', plays: '2.7B'),
      HomeTrack(videoId: 'V9PVRfjEBTI', title: 'BIRDS OF A FEATHER', artist: 'Billie Eilish', duration: '3:42', plays: '1.5B'),
      HomeTrack(videoId: 'Oa_RSwwpPaA', title: 'Beautiful Things', artist: 'Benson Boone', duration: '3:30', plays: '2.6B'),
      HomeTrack(videoId: '0U_7gdlR5I0', title: 'Lose Control', artist: 'Teddy Swims', duration: '3:40', plays: '650M'),
    ],
  );

  static const _rapAfricain = HomeSection(
    title: 'Rap Africain',
    type: HomeSectionType.tracks,
    tracks: [
      HomeTrack(videoId: 'Tw08lNebAjE', title: 'DtMF', artist: 'Bad Bunny', duration: '3:12', plays: '175M'),
      HomeTrack(videoId: 'uLK2r3sG4lE', title: 'PUSH 2 START', artist: 'Tyla', duration: '3:25', plays: '153M'),
      HomeTrack(videoId: 'dIQlZvPI_ac', title: 'Gata Only', artist: 'FloyyMenor & Cris MJ', duration: '3:00', plays: '1.1B'),
      HomeTrack(videoId: 'SOJpE1KMUbo', title: 'Raindance', artist: 'Dave', duration: '3:40', plays: '156M'),
      HomeTrack(videoId: 'lIxQe1R5hs0', title: 'Stateside', artist: 'PinkPantheress & Zara Larsson', duration: '3:15', plays: '64M'),
      HomeTrack(videoId: 'u2ah9tWTkmk', title: 'Ordinary', artist: 'Alex Warren', duration: '3:30', plays: '336M'),
      HomeTrack(videoId: 'aSugSGCC12I', title: 'Manchild', artist: 'Sabrina Carpenter', duration: '3:18', plays: '476M'),
      HomeTrack(videoId: 'rK5TyISxZ_M', title: 'WHERE IS MY HUSBAND!', artist: 'RAYE', duration: '2:45', plays: '19M'),
      HomeTrack(videoId: '3triLkS0nq4', title: 'Rein Me In', artist: 'Sam Fender & Olivia Dean', duration: '4:20', plays: '13M'),
      HomeTrack(videoId: 'BDHM8cyJQa8', title: 'That\'s So True', artist: 'Gracie Abrams', duration: '2:48', plays: '234M'),
    ],
  );

  static const _artistesPopulaires = HomeSection(
    title: 'Artistes populaires',
    type: HomeSectionType.artists,
    artists: [
      HomeArtist(name: 'Taylor Swift', image: 'images/artists/Taylor-Swift.jpg', listeners: '128.5M'),
      HomeArtist(name: 'Bruno Mars', image: 'images/artists/Bruno-Mars.jpg', listeners: '95.3M'),
      HomeArtist(name: 'Bad Bunny', image: 'images/artists/Bad-Bunny.jpg', listeners: '82.1M'),
      HomeArtist(name: 'Harry Styles', image: 'images/artists/Harry-Styles.jpg', listeners: '58.9M'),
      HomeArtist(name: 'Sabrina Carpenter', image: 'images/artists/Sabrina-Carpenter.jpg', listeners: '47.8M'),
      HomeArtist(name: 'Olivia Dean', image: 'images/artists/Olivia-Dean.jpg', listeners: '12.4M'),
      HomeArtist(name: 'Billie Eilish', image: 'images/artists/Billie-Eilish.jpg', listeners: '73.2M'),
      HomeArtist(name: 'Lady Gaga', image: 'images/artists/Lady-Gaga.jpg', listeners: '68.7M'),
      HomeArtist(name: 'Ed Sheeran', image: 'images/artists/Ed-Sheeran.jpg', listeners: '92.1M'),
      HomeArtist(name: 'Dave', image: 'images/artists/Dave.jpg', listeners: '18.6M'),
    ],
  );

  static const _albumsPopulaires = HomeSection(
    title: 'Albums populaires',
    type: HomeSectionType.albums,
    albums: [
      HomeAlbum(title: 'The Fate of Ophelia', artist: 'Taylor Swift', image: 'images/albums/Taylor-Fate.jpg', year: '2026'),
      HomeAlbum(title: 'Risk It All', artist: 'Bruno Mars', image: 'images/albums/Bruno-Risk.jpg', year: '2026'),
      HomeAlbum(title: 'Harry\'s House', artist: 'Harry Styles', image: 'images/albums/Harry-House.jpg', year: '2022'),
      HomeAlbum(title: 'Short n\' Sweet', artist: 'Sabrina Carpenter', image: 'images/albums/Sabrina-Short.jpg', year: '2024'),
      HomeAlbum(title: 'Ordinary', artist: 'Alex Warren', image: 'images/albums/Alex-Ordinary.jpg', year: '2025'),
      HomeAlbum(title: 'BRAT', artist: 'Charli XCX', image: 'images/albums/Charli-BRAT.jpg', year: '2024'),
      HomeAlbum(title: 'Ditto', artist: 'Tyler, The Creator', image: 'images/albums/Tyler-Ditto.jpg', year: '2025'),
      HomeAlbum(title: 'The Life of a Don', artist: 'Don Toliver', image: 'images/albums/Don-Life.jpg', year: '2025'),
      HomeAlbum(title: 'Gloria', artist: 'Mitski', image: 'images/albums/Mitski-Gloria.jpg', year: '2026'),
      HomeAlbum(title: 'Eusheen', artist: 'Destroy Lonely', image: 'images/albums/Destroy-Eusheen.jpg', year: '2025'),
      HomeAlbum(title: 'UTOPIA', artist: 'Travis Scott', image: 'images/albums/UTOPIA.jpg', year: '2023'),
      HomeAlbum(title: 'For All The Dogs', artist: 'Drake', image: 'images/albums/For-All-The-Dogs.jpg', year: '2023'),
      HomeAlbum(title: 'Midnights', artist: 'Taylor Swift', image: 'images/albums/Taylor-Midnights.jpg', year: '2022'),
      HomeAlbum(title: 'Harry\'s House', artist: 'Harry Styles', image: 'images/albums/Harry-House.jpg', year: '2022'),
      HomeAlbum(title: 'Renaissance', artist: 'Beyoncé', image: 'images/albums/Beyonce-Renaissance.jpg', year: '2022'),
      HomeAlbum(title: 'Dawn FM', artist: 'The Weeknd', image: 'images/albums/Weeknd-Dawn.jpg', year: '2022'),
      HomeAlbum(title: 'Planet Her', artist: 'Doja Cat', image: 'images/albums/Doja-Planet.jpg', year: '2021'),
      HomeAlbum(title: 'Take Care 2', artist: 'Drake', image: 'images/albums/Drake-Take2.jpg', year: '2025'),
      HomeAlbum(title: 'Swimming', artist: 'Mac Miller', image: 'images/albums/Mac-Swimming.jpg', year: '2018'),
      HomeAlbum(title: 'After Hours', artist: 'The Weeknd', image: 'images/albums/Weeknd-After.jpg', year: '2020'),
      HomeAlbum(title: 'Folklore', artist: 'Taylor Swift', image: 'images/albums/Taylor-Folklore.jpg', year: '2020'),
      HomeAlbum(title: 'When We All Fall', artist: 'Maren Morris', image: 'images/albums/Maren-Fall.jpg', year: '2025'),
      HomeAlbum(title: 'Elliot', artist: 'Clairo', image: 'images/albums/Clairo-Elliot.jpg', year: '2025'),
      HomeAlbum(title: 'I Got a Story', artist: 'Phoebe Bridgers', image: 'images/albums/Phoebe-Story.jpg', year: '2025'),
      HomeAlbum(title: 'The Record', artist: 'Boy Pablo', image: 'images/albums/BoyPablo-Record.jpg', year: '2025'),
    ],
  );

  static const _chansonsTendance = HomeSection(
    title: 'Chansons tendance',
    type: HomeSectionType.tracks,
    tracks: [
      HomeTrack(videoId: 'ko70cExuzZM', title: 'The Fate of Ophelia', artist: 'Taylor Swift', duration: '4:12', plays: '359M'),
      HomeTrack(videoId: 'mrV8kK5t0V8', title: 'I Just Might', artist: 'Bruno Mars', duration: '3:45', plays: '129M'),
      HomeTrack(videoId: 'lY5V4hSLWY8', title: 'Risk It All', artist: 'Bruno Mars', duration: '3:28', plays: '76M'),
      HomeTrack(videoId: '7sxVHYZ_PnA', title: 'Aperture', artist: 'Harry Styles', duration: '3:50', plays: '28M'),
      HomeTrack(videoId: 'hUbm0IpeNuk', title: 'Man I Need', artist: 'Olivia Dean', duration: '3:35', plays: '113M'),
      HomeTrack(videoId: 'rK5TyISxZ_M', title: 'WHERE IS MY HUSBAND!', artist: 'RAYE', duration: '2:45', plays: '19M'),
      HomeTrack(videoId: 'SOJpE1KMUbo', title: 'Raindance', artist: 'Dave', duration: '3:40', plays: '156M'),
      HomeTrack(videoId: 'lIxQe1R5hs0', title: 'Stateside', artist: 'PinkPantheress & Zara Larsson', duration: '3:15', plays: '64M'),
      HomeTrack(videoId: '3triLkS0nq4', title: 'Rein Me In', artist: 'Sam Fender & Olivia Dean', duration: '4:20', plays: '13M'),
      HomeTrack(videoId: 'u2ah9tWTkmk', title: 'Ordinary', artist: 'Alex Warren', duration: '3:30', plays: '336M'),
    ],
  );

  static const _top50RapMonde = HomeSection(
    title: 'Top 50 Rap Monde',
    type: HomeSectionType.tracks,
    tracks: [
      HomeTrack(videoId: 'Tw08lNebAjE', title: 'DtMF', artist: 'Bad Bunny', duration: '3:12', plays: '175M'),
      HomeTrack(videoId: '4QIZE708gJ4', title: 'I Had Some Help', artist: 'Post Malone & Morgan Wallen', duration: '3:30', plays: '236M'),
      HomeTrack(videoId: 'ecVKhR5cnGg', title: 'Lovin On Me', artist: 'Jack Harlow', duration: '3:25', plays: '227M'),
      HomeTrack(videoId: 'dIQlZvPI_ac', title: 'Gata Only', artist: 'FloyyMenor & Cris MJ', duration: '3:00', plays: '1.1B'),
      HomeTrack(videoId: 'uLK2r3sG4lE', title: 'PUSH 2 START', artist: 'Tyla', duration: '3:25', plays: '153M'),
      HomeTrack(videoId: 'u2ah9tWTkmk', title: 'Ordinary', artist: 'Alex Warren', duration: '3:30', plays: '336M'),
      HomeTrack(videoId: 'aSugSGCC12I', title: 'Manchild', artist: 'Sabrina Carpenter', duration: '3:18', plays: '476M'),
      HomeTrack(videoId: 'kPa7bsKwL-c', title: 'Die With A Smile', artist: 'Lady Gaga & Bruno Mars', duration: '4:11', plays: '3.1B'),
      HomeTrack(videoId: 'ekr2nIex040', title: 'APT.', artist: 'ROSÉ & Bruno Mars', duration: '3:15', plays: '2.7B'),
      HomeTrack(videoId: 'V9PVRfjEBTI', title: 'BIRDS OF A FEATHER', artist: 'Billie Eilish', duration: '3:42', plays: '1.5B'),
      HomeTrack(videoId: 'Oa_RSwwpPaA', title: 'Beautiful Things', artist: 'Benson Boone', duration: '3:30', plays: '2.6B'),
      HomeTrack(videoId: '0U_7gdlR5I0', title: 'Lose Control', artist: 'Teddy Swims', duration: '3:40', plays: '650M'),
    ],
  );

  static const _nouvellesSorties = HomeSection(
    title: 'Nouvelles sorties',
    type: HomeSectionType.tracks,
    tracks: [
      HomeTrack(videoId: 'ko70cExuzZM', title: 'The Fate of Ophelia', artist: 'Taylor Swift', duration: '4:12', plays: '359M'),
      HomeTrack(videoId: 'mrV8kK5t0V8', title: 'I Just Might', artist: 'Bruno Mars', duration: '3:45', plays: '129M'),
      HomeTrack(videoId: 'lY5V4hSLWY8', title: 'Risk It All', artist: 'Bruno Mars', duration: '3:28', plays: '76M'),
      HomeTrack(videoId: '7sxVHYZ_PnA', title: 'Aperture', artist: 'Harry Styles', duration: '3:50', plays: '28M'),
      HomeTrack(videoId: 'hUbm0IpeNuk', title: 'Man I Need', artist: 'Olivia Dean', duration: '3:35', plays: '113M'),
      HomeTrack(videoId: 'rK5TyISxZ_M', title: 'WHERE IS MY HUSBAND!', artist: 'RAYE', duration: '2:45', plays: '19M'),
      HomeTrack(videoId: 'SOJpE1KMUbo', title: 'Raindance', artist: 'Dave', duration: '3:40', plays: '156M'),
      HomeTrack(videoId: 'lIxQe1R5hs0', title: 'Stateside', artist: 'PinkPantheress & Zara Larsson', duration: '3:15', plays: '64M'),
      HomeTrack(videoId: '3triLkS0nq4', title: 'Rein Me In', artist: 'Sam Fender & Olivia Dean', duration: '4:20', plays: '13M'),
      HomeTrack(videoId: 'u2ah9tWTkmk', title: 'Ordinary', artist: 'Alex Warren', duration: '3:30', plays: '336M'),
    ],
  );

  static const _nouveauxAlbums = HomeSection(
    title: 'Nouveaux albums',
    type: HomeSectionType.tracks,
    tracks: [
      HomeTrack(videoId: 'V9PVRfjEBTI', title: 'BIRDS OF A FEATHER', artist: 'Billie Eilish', duration: '3:42', plays: '1.5B'),
      HomeTrack(videoId: 'kPa7bsKwL-c', title: 'Die With A Smile', artist: 'Lady Gaga & Bruno Mars', duration: '4:11', plays: '3.1B'),
      HomeTrack(videoId: 'ekr2nIex040', title: 'APT.', artist: 'ROSÉ & Bruno Mars', duration: '3:15', plays: '2.7B'),
      HomeTrack(videoId: '0U_7gdlR5I0', title: 'Lose Control', artist: 'Teddy Swims', duration: '3:40', plays: '650M'),
      HomeTrack(videoId: '1RKqOmSkGgM', title: 'Good Luck, Babe!', artist: 'Chappell Roan', duration: '3:48', plays: '148M'),
      HomeTrack(videoId: 'Oa_RSwwpPaA', title: 'Beautiful Things', artist: 'Benson Boone', duration: '3:30', plays: '2.6B'),
      HomeTrack(videoId: '4QIZE708gJ4', title: 'I Had Some Help', artist: 'Post Malone & Morgan Wallen', duration: '3:30', plays: '236M'),
      HomeTrack(videoId: 'ecVKhR5cnGg', title: 'Lovin On Me', artist: 'Jack Harlow', duration: '3:25', plays: '227M'),
      HomeTrack(videoId: 'V9vuCByb6js', title: 'Tears', artist: 'Sabrina Carpenter', duration: '3:45', plays: '48M'),
      HomeTrack(videoId: 'JgDNFQ2RaLQ', title: 'Sapphire', artist: 'Ed Sheeran', duration: '3:50', plays: '189M'),
    ],
  );

  static const _decouvertesSemaine = HomeSection(
    title: 'Découvertes de la semaine',
    type: HomeSectionType.tracks,
    tracks: [
      HomeTrack(videoId: 'Tw08lNebAjE', title: 'DtMF', artist: 'Bad Bunny', duration: '3:12', plays: '175M'),
      HomeTrack(videoId: 'uLK2r3sG4lE', title: 'PUSH 2 START', artist: 'Tyla', duration: '3:25', plays: '153M'),
      HomeTrack(videoId: 'dIQlZvPI_ac', title: 'Gata Only', artist: 'FloyyMenor & Cris MJ', duration: '3:00', plays: '1.1B'),
      HomeTrack(videoId: 'SOJpE1KMUbo', title: 'Raindance', artist: 'Dave', duration: '3:40', plays: '156M'),
      HomeTrack(videoId: 'lIxQe1R5hs0', title: 'Stateside', artist: 'PinkPantheress & Zara Larsson', duration: '3:15', plays: '64M'),
      HomeTrack(videoId: 'u2ah9tWTkmk', title: 'Ordinary', artist: 'Alex Warren', duration: '3:30', plays: '336M'),
      HomeTrack(videoId: 'aSugSGCC12I', title: 'Manchild', artist: 'Sabrina Carpenter', duration: '3:18', plays: '476M'),
      HomeTrack(videoId: 'rK5TyISxZ_M', title: 'WHERE IS MY HUSBAND!', artist: 'RAYE', duration: '2:45', plays: '19M'),
      HomeTrack(videoId: '3triLkS0nq4', title: 'Rein Me In', artist: 'Sam Fender & Olivia Dean', duration: '4:20', plays: '13M'),
      HomeTrack(videoId: 'BDHM8cyJQa8', title: 'That\'s So True', artist: 'Gracie Abrams', duration: '2:48', plays: '234M'),
    ],
  );

  static const _parceQueVousAvez = HomeSection(
    title: 'Parce que vous avez écouté',
    type: HomeSectionType.tracks,
    tracks: [
      HomeTrack(videoId: 'ko70cExuzZM', title: 'The Fate of Ophelia', artist: 'Taylor Swift', duration: '4:12', plays: '359M'),
      HomeTrack(videoId: 'mrV8kK5t0V8', title: 'I Just Might', artist: 'Bruno Mars', duration: '3:45', plays: '129M'),
      HomeTrack(videoId: 'lY5V4hSLWY8', title: 'Risk It All', artist: 'Bruno Mars', duration: '3:28', plays: '76M'),
      HomeTrack(videoId: '7sxVHYZ_PnA', title: 'Aperture', artist: 'Harry Styles', duration: '3:50', plays: '28M'),
      HomeTrack(videoId: 'hUbm0IpeNuk', title: 'Man I Need', artist: 'Olivia Dean', duration: '3:35', plays: '113M'),
      HomeTrack(videoId: 'rK5TyISxZ_M', title: 'WHERE IS MY HUSBAND!', artist: 'RAYE', duration: '2:45', plays: '19M'),
      HomeTrack(videoId: 'SOJpE1KMUbo', title: 'Raindance', artist: 'Dave', duration: '3:40', plays: '156M'),
      HomeTrack(videoId: 'lIxQe1R5hs0', title: 'Stateside', artist: 'PinkPantheress & Zara Larsson', duration: '3:15', plays: '64M'),
      HomeTrack(videoId: '3triLkS0nq4', title: 'Rein Me In', artist: 'Sam Fender & Olivia Dean', duration: '4:20', plays: '13M'),
      HomeTrack(videoId: 'u2ah9tWTkmk', title: 'Ordinary', artist: 'Alex Warren', duration: '3:30', plays: '336M'),
    ],
  );

  static const _vosArtistesPref = HomeSection(
    title: 'Vos artistes préférés',
    type: HomeSectionType.artists,
    artists: [
      HomeArtist(name: 'PinkPantheress', image: 'images/artists/PinkPantheress.jpg', listeners: '28.5M'),
      HomeArtist(name: 'Sam Fender', image: 'images/artists/Sam-Fender.jpg', listeners: '15.3M'),
      HomeArtist(name: 'Chappell Roan', image: 'images/artists/Chappell-Roan.jpg', listeners: '38.9M'),
      HomeArtist(name: 'Gracie Abrams', image: 'images/artists/Gracie-Abrams.jpg', listeners: '22.8M'),
      HomeArtist(name: 'Alex Warren', image: 'images/artists/Alex-Warren.jpg', listeners: '12.1M'),
      HomeArtist(name: 'Benson Boone', image: 'images/artists/Benson-Boone.jpg', listeners: '42.4M'),
      HomeArtist(name: 'Teddy Swims', image: 'images/artists/Teddy-Swims.jpg', listeners: '33.2M'),
      HomeArtist(name: 'RAYE', image: 'images/artists/RAYE.jpg', listeners: '18.7M'),
      HomeArtist(name: 'Tyla', image: 'images/artists/Tyla.jpg', listeners: '52.1M'),
      HomeArtist(name: 'ROSÉ', image: 'images/artists/ROSE.jpg', listeners: '78.6M'),
    ],
  );

  static const _vosChansonsPref = HomeSection(
    title: 'Vos chansons préférées',
    type: HomeSectionType.tracks,
    tracks: [
      HomeTrack(videoId: 'ko70cExuzZM', title: 'The Fate of Ophelia', artist: 'Taylor Swift', duration: '4:12', plays: '359M'),
      HomeTrack(videoId: 'mrV8kK5t0V8', title: 'I Just Might', artist: 'Bruno Mars', duration: '3:45', plays: '129M'),
      HomeTrack(videoId: 'lY5V4hSLWY8', title: 'Risk It All', artist: 'Bruno Mars', duration: '3:28', plays: '76M'),
      HomeTrack(videoId: '7sxVHYZ_PnA', title: 'Aperture', artist: 'Harry Styles', duration: '3:50', plays: '28M'),
      HomeTrack(videoId: 'hUbm0IpeNuk', title: 'Man I Need', artist: 'Olivia Dean', duration: '3:35', plays: '113M'),
      HomeTrack(videoId: 'rK5TyISxZ_M', title: 'WHERE IS MY HUSBAND!', artist: 'RAYE', duration: '2:45', plays: '19M'),
      HomeTrack(videoId: 'SOJpE1KMUbo', title: 'Raindance', artist: 'Dave', duration: '3:40', plays: '156M'),
      HomeTrack(videoId: 'lIxQe1R5hs0', title: 'Stateside', artist: 'PinkPantheress & Zara Larsson', duration: '3:15', plays: '64M'),
      HomeTrack(videoId: '3triLkS0nq4', title: 'Rein Me In', artist: 'Sam Fender & Olivia Dean', duration: '4:20', plays: '13M'),
      HomeTrack(videoId: 'u2ah9tWTkmk', title: 'Ordinary', artist: 'Alex Warren', duration: '3:30', plays: '336M'),
    ],
  );

  static const _afroDrill = HomeSection(
    title: 'Afro Drill',
    type: HomeSectionType.tracks,
    tracks: [
      HomeTrack(videoId: 'Tw08lNebAjE', title: 'DtMF', artist: 'Bad Bunny', duration: '3:12', plays: '175M'),
      HomeTrack(videoId: 'uLK2r3sG4lE', title: 'PUSH 2 START', artist: 'Tyla', duration: '3:25', plays: '153M'),
      HomeTrack(videoId: 'dIQlZvPI_ac', title: 'Gata Only', artist: 'FloyyMenor & Cris MJ', duration: '3:00', plays: '1.1B'),
      HomeTrack(videoId: 'SOJpE1KMUbo', title: 'Raindance', artist: 'Dave', duration: '3:40', plays: '156M'),
      HomeTrack(videoId: 'lIxQe1R5hs0', title: 'Stateside', artist: 'PinkPantheress & Zara Larsson', duration: '3:15', plays: '64M'),
      HomeTrack(videoId: 'u2ah9tWTkmk', title: 'Ordinary', artist: 'Alex Warren', duration: '3:30', plays: '336M'),
      HomeTrack(videoId: 'aSugSGCC12I', title: 'Manchild', artist: 'Sabrina Carpenter', duration: '3:18', plays: '476M'),
      HomeTrack(videoId: 'rK5TyISxZ_M', title: 'WHERE IS MY HUSBAND!', artist: 'RAYE', duration: '2:45', plays: '19M'),
      HomeTrack(videoId: '3triLkS0nq4', title: 'Rein Me In', artist: 'Sam Fender & Olivia Dean', duration: '4:20', plays: '13M'),
      HomeTrack(videoId: 'BDHM8cyJQa8', title: 'That\'s So True', artist: 'Gracie Abrams', duration: '2:48', plays: '234M'),
    ],
  );

  static const _plusADecouvrir = HomeSection(
    title: 'Plus à découvrir',
    type: HomeSectionType.tracks,
    tracks: [
      HomeTrack(videoId: 'Tw08lNebAjE', title: 'DtMF', artist: 'Bad Bunny', duration: '3:12', plays: '175M'),
      HomeTrack(videoId: 'uLK2r3sG4lE', title: 'PUSH 2 START', artist: 'Tyla', duration: '3:25', plays: '153M'),
      HomeTrack(videoId: 'dIQlZvPI_ac', title: 'Gata Only', artist: 'FloyyMenor & Cris MJ', duration: '3:00', plays: '1.1B'),
      HomeTrack(videoId: 'SOJpE1KMUbo', title: 'Raindance', artist: 'Dave', duration: '3:40', plays: '156M'),
      HomeTrack(videoId: 'lIxQe1R5hs0', title: 'Stateside', artist: 'PinkPantheress & Zara Larsson', duration: '3:15', plays: '64M'),
      HomeTrack(videoId: 'u2ah9tWTkmk', title: 'Ordinary', artist: 'Alex Warren', duration: '3:30', plays: '336M'),
      HomeTrack(videoId: 'aSugSGCC12I', title: 'Manchild', artist: 'Sabrina Carpenter', duration: '3:18', plays: '476M'),
      HomeTrack(videoId: 'rK5TyISxZ_M', title: 'WHERE IS MY HUSBAND!', artist: 'RAYE', duration: '2:45', plays: '19M'),
      HomeTrack(videoId: '3triLkS0nq4', title: 'Rein Me In', artist: 'Sam Fender & Olivia Dean', duration: '4:20', plays: '13M'),
      HomeTrack(videoId: 'BDHM8cyJQa8', title: 'That\'s So True', artist: 'Gracie Abrams', duration: '2:48', plays: '234M'),
    ],
  );

  static const _classiquesRap = HomeSection(
    title: 'Classiques du Rap',
    type: HomeSectionType.tracks,
    tracks: [
      HomeTrack(videoId: '4NRXx6U8ABQ', title: 'Blinding Lights', artist: 'The Weeknd', duration: '3:20', plays: '3.9B'),
      HomeTrack(videoId: 'kPa7bsKwL-c', title: 'Die With A Smile', artist: 'Lady Gaga & Bruno Mars', duration: '4:11', plays: '3.1B'),
      HomeTrack(videoId: 'ekr2nIex040', title: 'APT.', artist: 'ROSÉ & Bruno Mars', duration: '3:15', plays: '2.7B'),
      HomeTrack(videoId: 'V9PVRfjEBTI', title: 'BIRDS OF A FEATHER', artist: 'Billie Eilish', duration: '3:42', plays: '1.5B'),
      HomeTrack(videoId: 'eVli-tstM5E', title: 'Espresso', artist: 'Sabrina Carpenter', duration: '3:07', plays: '2.1B'),
      HomeTrack(videoId: 'Oa_RSwwpPaA', title: 'Beautiful Things', artist: 'Benson Boone', duration: '3:30', plays: '2.6B'),
      HomeTrack(videoId: '0U_7gdlR5I0', title: 'Lose Control', artist: 'Teddy Swims', duration: '3:40', plays: '650M'),
      HomeTrack(videoId: '1RKqOmSkGgM', title: 'Good Luck, Babe!', artist: 'Chappell Roan', duration: '3:48', plays: '148M'),
      HomeTrack(videoId: 'Z3aduh5fxCo', title: 'Show Me Love', artist: 'WizTheMc', duration: '3:10', plays: '716M'),
      HomeTrack(videoId: '4QIZE708gJ4', title: 'I Had Some Help', artist: 'Post Malone & Morgan Wallen', duration: '3:30', plays: '236M'),
    ],
  );

  static const _tendancesRapFR = HomeSection(
    title: 'Tendances Rap FR',
    type: HomeSectionType.tracks,
    tracks: [
      HomeTrack(videoId: 'Tw08lNebAjE', title: 'DtMF', artist: 'Bad Bunny', duration: '3:12', plays: '175M'),
      HomeTrack(videoId: 'uLK2r3sG4lE', title: 'PUSH 2 START', artist: 'Tyla', duration: '3:25', plays: '153M'),
      HomeTrack(videoId: 'dIQlZvPI_ac', title: 'Gata Only', artist: 'FloyyMenor & Cris MJ', duration: '3:00', plays: '1.1B'),
      HomeTrack(videoId: 'SOJpE1KMUbo', title: 'Raindance', artist: 'Dave', duration: '3:40', plays: '156M'),
      HomeTrack(videoId: 'lIxQe1R5hs0', title: 'Stateside', artist: 'PinkPantheress & Zara Larsson', duration: '3:15', plays: '64M'),
      HomeTrack(videoId: 'u2ah9tWTkmk', title: 'Ordinary', artist: 'Alex Warren', duration: '3:30', plays: '336M'),
      HomeTrack(videoId: 'aSugSGCC12I', title: 'Manchild', artist: 'Sabrina Carpenter', duration: '3:18', plays: '476M'),
      HomeTrack(videoId: 'rK5TyISxZ_M', title: 'WHERE IS MY HUSBAND!', artist: 'RAYE', duration: '2:45', plays: '19M'),
      HomeTrack(videoId: '3triLkS0nq4', title: 'Rein Me In', artist: 'Sam Fender & Olivia Dean', duration: '4:20', plays: '13M'),
      HomeTrack(videoId: 'BDHM8cyJQa8', title: 'That\'s So True', artist: 'Gracie Abrams', duration: '2:48', plays: '234M'),
    ],
  );

  static const _dancePop = HomeSection(
    title: 'Dance & Pop',
    type: HomeSectionType.tracks,
    tracks: [
      HomeTrack(videoId: 'ko70cExuzZM', title: 'The Fate of Ophelia', artist: 'Taylor Swift', duration: '4:12', plays: '359M'),
      HomeTrack(videoId: 'mrV8kK5t0V8', title: 'I Just Might', artist: 'Bruno Mars', duration: '3:45', plays: '129M'),
      HomeTrack(videoId: 'lY5V4hSLWY8', title: 'Risk It All', artist: 'Bruno Mars', duration: '3:28', plays: '76M'),
      HomeTrack(videoId: '7sxVHYZ_PnA', title: 'Aperture', artist: 'Harry Styles', duration: '3:50', plays: '28M'),
      HomeTrack(videoId: 'hUbm0IpeNuk', title: 'Man I Need', artist: 'Olivia Dean', duration: '3:35', plays: '113M'),
      HomeTrack(videoId: 'rK5TyISxZ_M', title: 'WHERE IS MY HUSBAND!', artist: 'RAYE', duration: '2:45', plays: '19M'),
      HomeTrack(videoId: 'SOJpE1KMUbo', title: 'Raindance', artist: 'Dave', duration: '3:40', plays: '156M'),
      HomeTrack(videoId: 'lIxQe1R5hs0', title: 'Stateside', artist: 'PinkPantheress & Zara Larsson', duration: '3:15', plays: '64M'),
      HomeTrack(videoId: '3triLkS0nq4', title: 'Rein Me In', artist: 'Sam Fender & Olivia Dean', duration: '4:20', plays: '13M'),
      HomeTrack(videoId: 'u2ah9tWTkmk', title: 'Ordinary', artist: 'Alex Warren', duration: '3:30', plays: '336M'),
    ],
  );

  static const _afrobeats = HomeSection(
    title: 'Afrobeats',
    type: HomeSectionType.tracks,
    tracks: [
      HomeTrack(videoId: 'Tw08lNebAjE', title: 'DtMF', artist: 'Bad Bunny', duration: '3:12', plays: '175M'),
      HomeTrack(videoId: 'uLK2r3sG4lE', title: 'PUSH 2 START', artist: 'Tyla', duration: '3:25', plays: '153M'),
      HomeTrack(videoId: 'dIQlZvPI_ac', title: 'Gata Only', artist: 'FloyyMenor & Cris MJ', duration: '3:00', plays: '1.1B'),
      HomeTrack(videoId: 'SOJpE1KMUbo', title: 'Raindance', artist: 'Dave', duration: '3:40', plays: '156M'),
      HomeTrack(videoId: 'lIxQe1R5hs0', title: 'Stateside', artist: 'PinkPantheress & Zara Larsson', duration: '3:15', plays: '64M'),
      HomeTrack(videoId: 'u2ah9tWTkmk', title: 'Ordinary', artist: 'Alex Warren', duration: '3:30', plays: '336M'),
      HomeTrack(videoId: 'aSugSGCC12I', title: 'Manchild', artist: 'Sabrina Carpenter', duration: '3:18', plays: '476M'),
      HomeTrack(videoId: 'rK5TyISxZ_M', title: 'WHERE IS MY HUSBAND!', artist: 'RAYE', duration: '2:45', plays: '19M'),
      HomeTrack(videoId: '3triLkS0nq4', title: 'Rein Me In', artist: 'Sam Fender & Olivia Dean', duration: '4:20', plays: '13M'),
      HomeTrack(videoId: 'BDHM8cyJQa8', title: 'That\'s So True', artist: 'Gracie Abrams', duration: '2:48', plays: '234M'),
    ],
  );

  static const _drillWorld = HomeSection(
    title: 'Drill World',
    type: HomeSectionType.tracks,
    tracks: [
      HomeTrack(videoId: 'Tw08lNebAjE', title: 'DtMF', artist: 'Bad Bunny', duration: '3:12', plays: '175M'),
      HomeTrack(videoId: 'uLK2r3sG4lE', title: 'PUSH 2 START', artist: 'Tyla', duration: '3:25', plays: '153M'),
      HomeTrack(videoId: 'dIQlZvPI_ac', title: 'Gata Only', artist: 'FloyyMenor & Cris MJ', duration: '3:00', plays: '1.1B'),
      HomeTrack(videoId: 'SOJpE1KMUbo', title: 'Raindance', artist: 'Dave', duration: '3:40', plays: '156M'),
      HomeTrack(videoId: 'lIxQe1R5hs0', title: 'Stateside', artist: 'PinkPantheress & Zara Larsson', duration: '3:15', plays: '64M'),
      HomeTrack(videoId: 'u2ah9tWTkmk', title: 'Ordinary', artist: 'Alex Warren', duration: '3:30', plays: '336M'),
      HomeTrack(videoId: 'aSugSGCC12I', title: 'Manchild', artist: 'Sabrina Carpenter', duration: '3:18', plays: '476M'),
      HomeTrack(videoId: 'rK5TyISxZ_M', title: 'WHERE IS MY HUSBAND!', artist: 'RAYE', duration: '2:45', plays: '19M'),
      HomeTrack(videoId: '3triLkS0nq4', title: 'Rein Me In', artist: 'Sam Fender & Olivia Dean', duration: '4:20', plays: '13M'),
      HomeTrack(videoId: 'BDHM8cyJQa8', title: 'That\'s So True', artist: 'Gracie Abrams', duration: '2:48', plays: '234M'),
    ],
  );

  static const _podcastsSection = HomeSection(
    title: 'Podcasts populaires',
    type: HomeSectionType.tracks,
    tracks: [
      HomeTrack(videoId: '6eHpTYJ1Vzo', title: 'The Joe Rogan Experience', artist: 'Joe Rogan', duration: '2:30:00', plays: '50M'),
      HomeTrack(videoId: 'a1W73x2BmDU', title: 'Call Her Daddy', artist: 'Alex Cooper', duration: '1:00:00', plays: '30M'),
      HomeTrack(videoId: 'Qp1s2s7QeXc', title: 'Crime Junkie', artist: 'Ashley Flowers', duration: '45:00', plays: '20M'),
      HomeTrack(videoId: '3nJ7Mf0x5fA', title: 'The Daily', artist: 'The New York Times', duration: '30:00', plays: '15M'),
      HomeTrack(videoId: 'L9b4G1oX5sA', title: 'Stuff You Should Know', artist: 'Josh Clark & Chuck Bryant', duration: '50:00', plays: '12M'),
      HomeTrack(videoId: 'm8fJ7V3b2cD', title: 'TED Talks Daily', artist: 'TED', duration: '20:00', plays: '25M'),
      HomeTrack(videoId: 'k5L6p8qR2sT', title: 'Serial', artist: 'Sarah Koenig', duration: '55:00', plays: '40M'),
      HomeTrack(videoId: 'n4D7g9hJ1kL', title: 'How I Built This', artist: 'Guy Raz', duration: '60:00', plays: '8M'),
      HomeTrack(videoId: 'pQ2r5s8tU3v', title: 'Science Vs', artist: 'Wendy Zukerman', duration: '40:00', plays: '6M'),
      HomeTrack(videoId: 'wX7y9zA4bC5', title: 'The Tim Ferriss Show', artist: 'Tim Ferriss', duration: '90:00', plays: '10M'),
    ],
  );
}
