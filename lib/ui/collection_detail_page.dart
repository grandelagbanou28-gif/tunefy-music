import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tunefy/data/home_data.dart';
import 'package:tunefy/models/home_track.dart';
import 'package:tunefy/models/track.dart';
import 'package:tunefy/services/itunes_service.dart';
import 'package:tunefy/services/muzo_service.dart';
import 'package:tunefy/helpers/tunefy_helpers.dart';
import 'package:tunefy/services/liked_service.dart';
import 'package:tunefy/DI/service_locator.dart';
import 'package:tunefy/widgets/add_to_playlist_sheet.dart';
import 'package:tunefy/theme/tunefy_colors.dart';
import 'dart:math' as math;

class CollectionDetailPage extends StatefulWidget {
  final HomeTrack heroTrack;
  final List<HomeTrack> allTracks;
  final String? albumTitle;
  final String? albumImage;
  final bool isAlbumView;
  final bool isPlaylistView;
  final List<HomeTrack>? heroTrackList;
  final int? collectionId;
  final String? browseId;

  const CollectionDetailPage({
    super.key,
    required this.heroTrack,
    required this.allTracks,
    this.albumTitle,
    this.albumImage,
    this.isAlbumView = false,
    this.isPlaylistView = false,
    this.heroTrackList,
    this.collectionId,
    this.browseId,
  });

  @override
  State<CollectionDetailPage> createState() => _CollectionDetailPageState();
}

class _CollectionDetailPageState extends State<CollectionDetailPage> {
  bool _isAdded = false;
  bool _isShuffle = false;
  bool _isLoading = false;

  List<HomeTrack> _artistTracks = [];
  List<HomeAlbum> _artistAlbums = [];
  List<HomeTrack> _similarTracks = [];
  List<Map<String, String>> _deezerPlaylists = [];
  String _totalDuration = '';
  String _heroImage = '';
  String _heroImageUrl = '';
  List<Map<String,dynamic>> _playlistData = [];

  static const _playlistImages = [
    'images/home/Daily-Mix-1.jpg','images/home/Upbeat-Mix.jpg','images/home/For-All-The-Dogs.jpg',
    'images/home/Rap-Workout.jpg','images/home/Drake-Mix.jpg','images/home/Offset-Mix.jpg',
    'images/home/chill-mix.png','images/home/2010s-mix.png','images/home/AUSTIN.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _heroImage = widget.albumImage ?? (artistImage(widget.heroTrack.artist) ?? '');
    _heroImageUrl = widget.heroTrack.imageUrl ?? '';
    if (widget.isAlbumView) {
      _artistTracks = widget.heroTrackList ?? [];
      debugPrint('CollectionDetailPage.initState: isAlbumView, heroTrackList=${widget.heroTrackList?.length}, _artistTracks=${_artistTracks.length}, albumTitle="${widget.albumTitle}", collectionId=${widget.collectionId}, browseId=${widget.browseId}');
      if (_artistTracks.isEmpty && widget.albumTitle != null) {
        _loadAlbumTracks(widget.albumTitle!, widget.heroTrack.artist, collectionId: widget.collectionId, browseId: widget.browseId);
      } else {
        if (_artistTracks.isNotEmpty) debugPrint('  Using heroTrackList directly (${_artistTracks.length} tracks)');
        _calcDuration();
        _buildPlaylistData();
      }
    } else if (widget.isPlaylistView) {
      _artistTracks = widget.heroTrackList ?? [widget.heroTrack];
      _calcDuration();
      _buildPlaylistData();
    } else {
      _loadArtistData();
    }
  }

  Future<void> _loadArtistData() async {
    final heroArtist = widget.heroTrack.artist;
    _isLoading = true;
    setState(() {});

    List<HomeTrack> artistTracks = [];
    try {
      artistTracks = await MuzoService.searchSongs(heroArtist, limit: 30);
      debugPrint('_loadArtistData: Muzo returned ${artistTracks.length} tracks for "$heroArtist"');
    } catch (_) {}
    if (artistTracks.isEmpty) {
      try {
        artistTracks = await ItunesService.fetchArtistTopTracks(heroArtist);
        debugPrint('_loadArtistData: iTunes returned ${artistTracks.length} tracks for "$heroArtist"');
      } catch (_) {}
    }
    if (artistTracks.isNotEmpty) {
      _artistTracks = artistTracks;
    } else {
      final seen = <String>{};
      final seenTitles = <String>{};
      final tracks = <HomeTrack>[];
      for (final t in widget.allTracks) {
        if (t.artist == heroArtist && seen.add(t.videoId)) {
          final norm = t.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          if (norm.isNotEmpty && seenTitles.add(norm)) tracks.add(t);
        }
      }
      if (tracks.isEmpty) {
        tracks.add(widget.heroTrack);
      }
      _artistTracks = tracks;
    }

    if (_heroImageUrl.isEmpty && _artistTracks.isNotEmpty) {
      _heroImageUrl = _artistTracks.first.imageUrl ?? '';
    }

    final deezerAlbums = await ItunesService.fetchArtistAlbums(heroArtist);
    if (!mounted) return;
    if (deezerAlbums.isNotEmpty) {
      final seenAlbumTitles = <String>{};
      _artistAlbums = [];
      for (final album in deezerAlbums) {
        if (seenAlbumTitles.add(album.title.toLowerCase())) {
          _artistAlbums.add(album);
        }
      }
    } else {
      for (final section in HomeData.sections) {
        if (section.type == HomeSectionType.albums) {
          for (final album in section.albums) {
            if (album.artist == heroArtist) _artistAlbums.add(album);
          }
        }
      }
      _artistAlbums = _artistAlbums.take(5).toList();
    }

    final similarTracks = <HomeTrack>[];
    final trackSeen = <String>{};
    for (final section in HomeData.sections) {
      if (section.type == HomeSectionType.tracks) {
        for (final t in section.tracks) {
          if (t.artist != heroArtist && trackSeen.add(t.videoId)) {
            similarTracks.add(t);
          }
        }
      }
    }
    if (similarTracks.isEmpty) {
      for (final t in widget.allTracks) {
        if (t.artist != heroArtist && trackSeen.add(t.videoId)) {
          similarTracks.add(t);
        }
      }
    }
    _similarTracks = similarTracks.take(10).toList();

    _deezerPlaylists = await ItunesService.fetchArtistPlaylists(heroArtist, limit: 5);
    if (!mounted) return;
    final seenPlTitles = <String>{};
    _deezerPlaylists = _deezerPlaylists.where((pl) {
      final t = (pl['title'] ?? '').toLowerCase();
      return seenPlTitles.add(t);
    }).toList();

    _calcDuration();
    _buildPlaylistData();
    _isLoading = false;
    setState(() {});
  }

  Future<void> _loadAlbumTracks(String albumTitle, String artistName, {int? collectionId, String? browseId}) async {
    debugPrint('_loadAlbumTracks: "$albumTitle" by "$artistName", collectionId=$collectionId, browseId=$browseId');
    _isLoading = true;
    setState(() {});
    List<HomeTrack> tracks = [];

    // 1) If we already have a Muzo browseId, try it first (fast path)
    if (browseId != null) {
      try {
        final muzoData = await MuzoService.getAlbumDetails(browseId);
        tracks = MuzoService.parseTracks(muzoData, fallbackArtist: artistName, fallbackImage: widget.albumImage ?? _heroImageUrl);
        debugPrint('  Muzo details(browseId): ${tracks.length} tracks');
      } catch (_) { debugPrint('  Muzo details FAILED'); }
      if (tracks.isNotEmpty) return _finishLoading(tracks);
    }

    // 2) iTunes Lookup by collectionId (fastest & most reliable for iTunes albums)
    if (tracks.isEmpty && collectionId != null) {
      try {
        tracks = await ItunesService.fetchAlbumTracks(collectionId);
        debugPrint('  iTunes Lookup(collectionId=$collectionId): ${tracks.length} tracks');
      } catch (_) { debugPrint('  iTunes Lookup FAILED'); }
      if (tracks.isNotEmpty) return _finishLoading(tracks);
    }

    // 3) Muzo search by title+artist (gives YouTube videoIds)
    if (tracks.isEmpty) {
      try {
        final muzoData = await MuzoService.searchAlbum(albumTitle, artistName);
        if (muzoData != null) tracks = MuzoService.parseTracks(muzoData, fallbackArtist: artistName, fallbackImage: widget.albumImage ?? _heroImageUrl);
        debugPrint('  Muzo search: ${tracks.length} tracks');
      } catch (_) { debugPrint('  Muzo search FAILED'); }
      if (tracks.isNotEmpty) return _finishLoading(tracks);
    }

    // 4) iTunes search by title (lenient match)
    if (tracks.isEmpty) {
      try {
        tracks = await ItunesService.fetchAlbumTracksByTitle(albumTitle, artistName);
        debugPrint('  iTunes ByTitle: ${tracks.length} tracks');
      } catch (_) { debugPrint('  iTunes ByTitle FAILED'); }
      if (tracks.isNotEmpty) return _finishLoading(tracks);
    }

    // 5) Last resort: artist top tracks
    if (tracks.isEmpty) {
      try {
        tracks = await ItunesService.fetchArtistTopTracks(artistName);
        debugPrint('  iTunes artist top tracks: ${tracks.length} tracks');
      } catch (_) { debugPrint('  iTunes artist top tracks FAILED'); }
    }

    _finishLoading(tracks);
  }

  void _finishLoading(List<HomeTrack> tracks) {
    if (!mounted) return;
    debugPrint('_loadAlbumTracks FINAL: ${tracks.length} tracks');
    if (tracks.isNotEmpty) {
      _artistTracks = tracks;
      if (tracks.first.imageUrl != null && tracks.first.imageUrl!.isNotEmpty) {
        _heroImageUrl = tracks.first.imageUrl!;
      }
    }
    _calcDuration();
    _isLoading = false;
    setState(() {});
  }

  void _calcDuration() {
    int totalSec = 0;
    for (final t in _artistTracks) {
      final p = t.duration.split(':');
      if (p.length == 2) totalSec += int.parse(p[0]) * 60 + int.parse(p[1]);
    }
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    _totalDuration = h > 0 ? '$h h ${m.toString().padLeft(2, '0')} min' : '$m min';
  }

  void _buildPlaylistData() {
    final heroArtist = widget.heroTrack.artist;
    final plNames = ['Daily Mix $heroArtist','Radio $heroArtist','Discover $heroArtist',
      'Top Hits $heroArtist','$heroArtist Essentials','$heroArtist Unplugged','Chill $heroArtist'];
    final plSubs = ['50 titres • 2 h 30','30 titres • 1 h 45','40 titres • 2 h 10',
      '50 titres • 2 h 55','35 titres • 1 h 55','25 titres • 1 h 30','45 titres • 2 h 20'];
    final plCount = _artistTracks.isEmpty ? 0 : 3 + (heroArtist.hashCode.abs() % 4);
    _playlistData = List.generate(plCount, (i) {
      final plTracks = <HomeTrack>[];
      if (_artistTracks.isNotEmpty) {
        final startIdx = (i * 5) % _artistTracks.length;
        for (int j = 0; j < 5 && j < _artistTracks.length; j++) {
          plTracks.add(_artistTracks[(startIdx + j) % _artistTracks.length]);
        }
      }
      return {
        'title': plNames[i % plNames.length],
        'sub': plSubs[i % plSubs.length],
        'img': _playlistImages[(heroArtist.hashCode.abs() + i) % _playlistImages.length],
        'tracks': plTracks,
      };
    });
  }

  String _trackThumb(HomeTrack t) {
    return artistImage(t.artist) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final artistName = widget.heroTrack.artist;
    return Scaffold(
      backgroundColor: TunefyColors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: w * 0.82,
            collapsedHeight: 56,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1A6B4F),
            leading: GestureDetector(
              onTap: () { haptic(); Navigator.pop(context); },
              child: const Icon(Icons.arrow_back_ios_new, color: TunefyColors.white, size: 22),
            ),
            title: Text(widget.albumTitle ?? artistName, style: const TextStyle(
              fontFamily: 'AB', fontSize: 16, color: TunefyColors.white, fontWeight: FontWeight.w700,
            )),
            centerTitle: true,
            actions: [
              GestureDetector(
                onTap: () { haptic(); _showPlaylistMenu(); },
                child: const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(Icons.more_vert, color: TunefyColors.white, size: 24),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1A6B4F), Color(0xFF0D4535), Color(0xFF062118), TunefyColors.black],
                    stops: [0.0, 0.25, 0.55, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 56),
                      Center(
                        child: Container(
                          width: w * 0.50, height: w * 0.50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(color: TunefyColors.green.withValues(alpha: 0.35), blurRadius: 44, offset: const Offset(0, 18)),
                            ],
                          ),
                            child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _heroImageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: _heroImageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(color: TunefyColors.darkCard),
                                    errorWidget: (_, __, ___) => Image.asset(
                                      widget.isAlbumView || widget.isPlaylistView
                                        ? (widget.albumImage ?? 'assets/tracks/${widget.heroTrack.videoId}.jpg')
                                        : 'assets/tracks/${widget.heroTrack.videoId}.jpg',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, ___, ____) => _heroFallback(),
                                    ),
                                  )
                                : Image.asset(
                                    widget.isAlbumView || widget.isPlaylistView
                                      ? (widget.albumImage ?? 'assets/tracks/${widget.heroTrack.videoId}.jpg')
                                      : 'assets/tracks/${widget.heroTrack.videoId}.jpg',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _heroFallback(),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildHeaderInfo()),
          SliverToBoxAdapter(child: _buildActionBar()),
          SliverToBoxAdapter(child: _buildSectionTitle('Titres')),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: TunefyColors.green, strokeWidth: 3)),
              ),
            )
          else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _buildTrackListTile(_artistTracks[i], i),
              childCount: _artistTracks.length,
            ),
          ),
          if (!widget.isAlbumView && !widget.isPlaylistView) ...[
            if (_artistAlbums.isNotEmpty) ...[
              SliverToBoxAdapter(child: _buildSectionTitle('Albums de l\'artiste')),
              SliverToBoxAdapter(child: _buildAlbumsRow(w)),
            ],
            if (_deezerPlaylists.isNotEmpty) ...[
              SliverToBoxAdapter(child: _buildSectionTitle('Playlists')),
              SliverToBoxAdapter(child: _buildPlaylistsRow(w)),
            ],
            if (_similarTracks.isNotEmpty) ...[
            SliverToBoxAdapter(child: _buildSectionTitle('Vous pourriez aimer')),
            SliverToBoxAdapter(child: _buildSimilarTracksRow(w)),
            ],
          ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _heroFallback() {
    return Container(color: TunefyColors.darkCard,
      child: const Icon(Icons.music_note, color: TunefyColors.grey, size: 64));
  }

  Widget _buildHeaderInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 14, backgroundImage: AssetImage("images/hivefy_logo.png")),
              const SizedBox(width: 8),
              const Text('TUNEFY', style: TextStyle(
                fontFamily: 'AB', fontSize: 12, color: TunefyColors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.albumTitle ?? widget.heroTrack.title,
            style: const TextStyle(fontFamily: 'AB', fontSize: 22, color: TunefyColors.white, fontWeight: FontWeight.w800),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(widget.heroTrack.artist, style: const TextStyle(
            fontFamily: 'AM', fontSize: 14, color: TunefyColors.grey,
          )),
          const SizedBox(height: 4),
          Text(
            widget.isAlbumView
              ? '${_artistTracks.length} titres • $_totalDuration'
              : widget.isPlaylistView
                ? '${_artistTracks.length} titres • $_totalDuration'
                : 'Conçu spécialement pour vous • ${_artistTracks.length} titres • $_totalDuration',
            style: const TextStyle(fontFamily: 'AM', fontSize: 12, color: TunefyColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              haptic();
              setState(() => _isAdded = !_isAdded);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(_isAdded ? 'Ajouté à la Bibliothèque' : 'Retiré de la Bibliothèque',
                  style: const TextStyle(fontFamily: 'AM', color: TunefyColors.white)),
                backgroundColor: TunefyColors.darkCard,
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ));
            },
            child: Icon(_isAdded ? Icons.check_circle : Icons.add_circle_outline,
              color: _isAdded ? TunefyColors.green : TunefyColors.white, size: 28),
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: () {
              haptic();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Téléchargement lancé', style: TextStyle(fontFamily: 'AM', color: TunefyColors.white)),
                backgroundColor: TunefyColors.darkCard,
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ));
            },
            child: const Icon(Icons.arrow_circle_down_outlined, color: TunefyColors.grey, size: 26),
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: () {
              haptic();
              final title = widget.albumTitle ?? widget.heroTrack.title;
Share.share('$title - ${widget.heroTrack.artist}');
            },
            child: const Icon(Icons.share_outlined, color: TunefyColors.grey, size: 24),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              haptic();
              setState(() => _isShuffle = !_isShuffle);
              if (_isShuffle && _artistTracks.isNotEmpty) {
                final shuffled = List<HomeTrack>.from(_artistTracks)..shuffle(math.Random());
                selectTrack(shuffled.first);
              }
            },
            child: Icon(Icons.shuffle, color: _isShuffle ? TunefyColors.green : TunefyColors.grey, size: 24),
          ),
          const SizedBox(width: 16),
          ValueListenableBuilder<bool>(
            valueListenable: globalIsPlaying,
            builder: (ctx, playing, _) {
              return ValueListenableBuilder<HomeTrack?>(
                valueListenable: globalActiveTrack,
                builder: (ctx, active, _) {
                  final isPageTrackPlaying = _artistTracks.any((t) =>
                    t.title.toLowerCase() == (active?.title ?? '').toLowerCase() &&
                    t.artist.toLowerCase() == (active?.artist ?? '').toLowerCase()) && playing;
                  return GestureDetector(
                    onTap: () {
                      haptic();
                      if (_artistTracks.isNotEmpty) {
                        if (isPageTrackPlaying) {
                          toggleGlobalPlay();
                        } else {
                          selectTrack(_artistTracks.first);
                        }
                      }
                    },
                    child: Container(
                      width: 52, height: 52,
                      decoration: const BoxDecoration(color: TunefyColors.green, shape: BoxShape.circle),
                      child: Icon(isPageTrackPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: TunefyColors.white, size: 30),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
      child: Text(title, style: const TextStyle(
        fontFamily: 'AB', fontSize: 16, color: TunefyColors.white, fontWeight: FontWeight.w700,
      )),
    );
  }

  Widget _buildTrackListTile(HomeTrack track, int index) {
    final thumbUrl = _trackThumb(track);
    final isExplicit = explicitIndices.contains(index % 80);
    return ValueListenableBuilder<HomeTrack?>(
      valueListenable: globalActiveTrack,
      builder: (ctx, active, _) {
        final isActive = active != null &&
            active.title.toLowerCase() == track.title.toLowerCase() &&
            active.artist.toLowerCase() == track.artist.toLowerCase();
        return ValueListenableBuilder<bool>(
          valueListenable: globalIsPlaying,
          builder: (ctx, playing, _) {
            return GestureDetector(
              onTap: () { haptic(); selectTrack(track); },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontFamily: 'AM', fontSize: 13,
                        color: isActive && playing ? TunefyColors.green : TunefyColors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TrackImage(track: track, width: 48, height: 48),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(track.title, style: TextStyle(
                            fontFamily: 'AB', fontSize: 14,
                            color: isActive && playing ? TunefyColors.green : TunefyColors.white,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (isExplicit) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                                  margin: const EdgeInsets.only(right: 5),
                                  decoration: BoxDecoration(
                                    color: TunefyColors.grey.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: const Text('E', style: TextStyle(fontFamily: 'AB', fontSize: 8, color: TunefyColors.white, fontWeight: FontWeight.w700)),
                                ),
                              ],
                              Expanded(
                                child: Text(track.artist, style: const TextStyle(
                                  fontFamily: 'AM', fontSize: 12, color: TunefyColors.grey,
                                ), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(width: 8),
                              Text(track.duration, style: const TextStyle(fontFamily: 'AM', fontSize: 11, color: TunefyColors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () { haptic(); _showTrackMenu(track); },
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.more_vert, color: TunefyColors.grey, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _tileThumb() {
    return Container(
      width: 44, height: 44, color: TunefyColors.darkCard,
      child: const Icon(Icons.music_note, color: TunefyColors.grey, size: 20),
    );
  }

  Widget _buildAlbumsRow(double w) {
    return SizedBox(
      height: w * 0.52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _artistAlbums.length,
        itemBuilder: (ctx, i) {
          final album = _artistAlbums[i];
          final albumImg = (album.imageUrl ?? '').isNotEmpty
              ? album.imageUrl!
              : (album.image);
          return GestureDetector(
            onTap: () {
              haptic();
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => CollectionDetailPage(
                  heroTrack: HomeTrack(
                    videoId: 'placeholder',
                    title: album.title,
                    artist: album.artist,
                    duration: '0:00',
                    imageUrl: albumImg,
                  ),
                  allTracks: widget.allTracks,
                  albumTitle: album.title,
                  albumImage: albumImg,
                  isAlbumView: true,
                  heroTrackList: [],
                  collectionId: album.collectionId,
                  browseId: album.browseId,
                ),
              ));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: w * 0.34, height: w * 0.34,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: ClipOval(
                      child: img(albumImg, w: w * 0.34, h: w * 0.34, err: (_, __, ___) => Container(
                        color: TunefyColors.darkCard,
                        child: const Icon(Icons.album, color: TunefyColors.grey, size: 28),
                      )),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(width: w * 0.34, child: Text(album.title,
                    style: const TextStyle(fontFamily: 'AB', fontSize: 12, color: TunefyColors.white),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(height: 2),
                  SizedBox(width: w * 0.34, child: Text(
                    album.trackCount > 0 ? '${album.trackCount} titres' : '${album.artist} • ${album.year}',
                    style: const TextStyle(fontFamily: 'AM', fontSize: 11, color: TunefyColors.grey),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaylistsRow(double w) {
    final playlists = _deezerPlaylists;
    if (playlists.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: w * 0.52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: playlists.length,
        itemBuilder: (ctx, i) {
          final pl = playlists[i];
          final plTitle = pl['title'] ?? '';
          final plImage = pl['image'] ?? '';
          final trackCount = pl['trackCount'] ?? '0';
          return GestureDetector(
            onTap: () async {
              haptic();
              List<HomeTrack> tracks = [];
              try {
                final muzoData = await MuzoService.searchAlbum(plTitle, widget.heroTrack.artist);
                tracks = MuzoService.parseTracks(muzoData, fallbackArtist: widget.heroTrack.artist, fallbackImage: plImage);
                debugPrint('_buildPlaylistsRow: Muzo returned ${tracks.length} tracks for "$plTitle"');
              } catch (_) {}
              if (tracks.isEmpty) {
                final plId = pl['id'] ?? '';
                if (plId.isEmpty) return;
                try {
                  tracks = await ItunesService.fetchPlaylistTracks(plId);
                  debugPrint('_buildPlaylistsRow: iTunes returned ${tracks.length} tracks');
                } catch (_) {}
              }
              if (tracks.isEmpty || !mounted) return;
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => CollectionDetailPage(
                  heroTrack: tracks.first,
                  allTracks: widget.allTracks,
                  albumTitle: plTitle,
                  albumImage: plImage,
                  isPlaylistView: true,
                  heroTrackList: tracks,
                ),
              ));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: w * 0.34, height: w * 0.34,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: plImage,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: TunefyColors.darkCard),
                        errorWidget: (_, __, ___) => Container(
                          color: TunefyColors.darkCard,
                          child: const Icon(Icons.queue_music, color: TunefyColors.grey, size: 28),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(width: w * 0.34, child: Text(plTitle,
                    style: const TextStyle(fontFamily: 'AB', fontSize: 12, color: TunefyColors.white),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(height: 2),
                  SizedBox(width: w * 0.34, child: Text('$trackCount titres',
                    style: const TextStyle(fontFamily: 'AM', fontSize: 11, color: TunefyColors.grey),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSimilarTracksRow(double w) {
    return SizedBox(
      height: w * 0.52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _similarTracks.length,
        itemBuilder: (ctx, i) {
          final track = _similarTracks[i];
          return GestureDetector(
            onTap: () {
              haptic();
              selectTrack(track);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TrackImage(track: track, width: w * 0.38, height: w * 0.38),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(width: w * 0.38, child: Text(track.title,
                    style: const TextStyle(fontFamily: 'AB', fontSize: 12, color: TunefyColors.white),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(height: 2),
                  SizedBox(width: w * 0.38, child: Text(track.artist,
                    style: const TextStyle(fontFamily: 'AM', fontSize: 11, color: TunefyColors.grey),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPlaylistMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: TunefyColors.black,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(color: TunefyColors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(6),
                    child: img(
                      widget.heroTrack.imageUrl ?? 'assets/tracks/${widget.heroTrack.videoId}.jpg',
                      w: 48, h: 48, err: (_, __, ___) => _menuThumb(),
                    )),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.heroTrack.title, style: const TextStyle(fontFamily: 'AB', fontSize: 14, color: TunefyColors.white),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      const Text('par Tunefy', style: TextStyle(fontFamily: 'AM', fontSize: 12, color: TunefyColors.grey)),
                    ],
                  )),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  _menuItem(Icons.share_outlined, 'Partager', onTap: () {
                    final title = widget.albumTitle ?? widget.heroTrack.title;
                    Share.share('$title - ${widget.heroTrack.artist}');
                    Navigator.pop(ctx);
                  }),
                  _menuItem(Icons.check_circle, 'Supprimer de la Bibliothèque', color: TunefyColors.green, onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Retiré de la Bibliothèque', style: TextStyle(fontFamily: 'AM', color: TunefyColors.white)),
                      backgroundColor: TunefyColors.darkCard,
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ));
                  }),
                  _menuItem(Icons.arrow_circle_down_outlined, 'Télécharger', badge: 'Premium'),
                  _menuItem(Icons.add_circle_outline, 'Ajouter à une autre playlist', onTap: () {
                    Navigator.pop(ctx);
                    if (_artistTracks.isNotEmpty) {
                      AddToPlaylistSheet.show(context, Track(
                        videoId: _artistTracks.first.videoId, title: _artistTracks.first.title,
                        artist: _artistTracks.first.artist, albumImage: _artistTracks.first.imageUrl,
                      ));
                    }
                  }),
                  _menuItem(Icons.groups_outlined, 'Lancer un Jam', badge: 'Premium'),
                  _menuItem(Icons.folder_outlined, 'Déplacer vers le dossier'),
                  _menuItem(Icons.person_outline, 'Ajouter à votre profil'),
                  _menuItem(Icons.cancel_outlined, 'Exclure la playlist du profil d\'écoute'),
                  _menuItem(Icons.qr_code_2, 'Afficher le code Tunefy'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuThumb() {
    return Container(width: 48, height: 48, color: TunefyColors.darkCard,
      child: const Icon(Icons.music_note, color: TunefyColors.grey, size: 20));
  }

  void _showTrackMenu(HomeTrack track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TunefyColors.black,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(color: TunefyColors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(6),
                    child: img(
                      track.imageUrl ?? 'assets/tracks/${track.videoId}.jpg',
                      w: 48, h: 48, err: (_, __, ___) => _menuThumb(),
                    )),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(track.title, style: const TextStyle(fontFamily: 'AB', fontSize: 14, color: TunefyColors.white),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(track.artist, style: const TextStyle(fontFamily: 'AM', fontSize: 12, color: TunefyColors.grey),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  )),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  _menuItem(Icons.share_outlined, 'Partager', onTap: () {
                    Share.share('${track.title} - ${track.artist}');
                    Navigator.pop(ctx);
                  }),
                  _menuItem(Icons.favorite_border, 'Ajouter aux Titres likés', onTap: () {
                    final model = Track(videoId: track.videoId, title: track.title, artist: track.artist, albumImage: track.imageUrl);
                    final isLiked = LikedService().isLiked(track.videoId);
                    if (isLiked) {
                      LikedService().remove(track.videoId);
                    } else {
                      LikedService().add(model);
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(isLiked ? 'Retiré des Titres likés' : 'Ajouté aux Titres likés',
                        style: const TextStyle(fontFamily: 'AM', color: TunefyColors.white)),
                      backgroundColor: TunefyColors.darkCard,
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ));
                  }),
                  _menuItem(Icons.playlist_add, 'Ajouter à la playlist', onTap: () {
                    Navigator.pop(ctx);
                    AddToPlaylistSheet.show(context, Track(
                      videoId: track.videoId, title: track.title, artist: track.artist, albumImage: track.imageUrl,
                    ));
                  }),
                  _menuItem(Icons.do_not_disturb_on_outlined, 'Masquer dans cette playlist'),
                  _menuItem(Icons.queue_music, 'Ajouter à la file d\'attente', onTap: () {
                    Navigator.pop(ctx);
                    final trackModel = Track(videoId: track.videoId, title: track.title, artist: track.artist, albumImage: track.imageUrl, duration: parseDuration(track.duration));
                    playerProvider.addToQueue(trackModel);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${track.title} ajouté à la file d\'attente',
                        style: const TextStyle(fontFamily: 'AM', color: TunefyColors.white)),
                      backgroundColor: TunefyColors.darkCard,
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ));
                  }),
                  _menuItem(Icons.album_outlined, 'Accéder à l\'album', onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => CollectionDetailPage(
                        heroTrack: HomeTrack(
                          videoId: track.videoId, title: track.title, artist: track.artist,
                          duration: track.duration, imageUrl: track.imageUrl,
                        ),
                        allTracks: widget.allTracks,
                        albumTitle: track.artist,
                        albumImage: track.imageUrl,
                        isAlbumView: true,
                      ),
                    ));
                  }),
                  _menuItem(Icons.person_outline, 'Accéder aux artistes', onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => CollectionDetailPage(
                        heroTrack: HomeTrack(
                          videoId: track.videoId, title: track.title, artist: track.artist,
                          duration: track.duration, imageUrl: track.imageUrl,
                        ),
                        allTracks: widget.allTracks,
                      ),
                    ));
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, {Color? color, String? badge, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: color ?? TunefyColors.white, size: 24),
      title: Row(
        children: [
          Flexible(child: Text(label, style: TextStyle(fontFamily: 'AM', fontSize: 14, color: color ?? TunefyColors.white),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: TunefyColors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(badge, style: const TextStyle(fontFamily: 'AB', fontSize: 10, color: TunefyColors.green, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
      onTap: onTap ?? () { haptic(); },
    );
  }
}
