import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tunefy/constants/constants.dart';
import 'package:tunefy/services/search_service.dart';
import 'package:tunefy/DI/service_locator.dart';
import 'package:tunefy/models/track.dart';
import 'package:tunefy/ui/collection_detail_screen.dart';
import 'package:tunefy/ui/track_detail_screen.dart';
import 'package:tunefy/widgets/bottom_player.dart';
import 'package:tunefy/services/haptic_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tunefy/theme/tunefy_theme.dart';

class ArtistDetailScreen extends StatefulWidget {
  final String title;
  final String? imageUrl;
  final String? subtitle;
  final String? browseId;

  const ArtistDetailScreen({
    super.key,
    required this.title,
    this.imageUrl,
    this.subtitle,
    this.browseId,
  });

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen>
    with SingleTickerProviderStateMixin {
  List<SearchResult> _tracks = [];
  List<SearchResult> _albums = [];
  List<SearchResult> _playlists = [];
  List<SearchResult> _related = [];
  bool _isLoadingTracks = true;
  bool _isLoadingAlbums = false;
  bool _isLoadingPlaylists = false;
  bool _isLoadingRelated = false;
  bool _isShuffleOn = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  bool get _isPlaying =>
      playerProvider.currentTrack != null && playerProvider.isPlaying;

  String _totalDuration() {
    int totalSeconds = 0;
    for (final t in _tracks) {
      if (t.duration != null && t.duration!.isNotEmpty) {
        final parts = t.duration!.split(':');
        if (parts.length == 2) {
          totalSeconds += (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
        } else if (parts.length == 3) {
          totalSeconds += (int.tryParse(parts[0]) ?? 0) * 3600 + (int.tryParse(parts[1]) ?? 0) * 60 + (int.tryParse(parts[2]) ?? 0);
        }
      }
    }
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h > 0) return '$h h $m min';
    return '$m min';
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
    playerProvider.addListener(_onPlayerChanged);
    _startLoading();
  }

  Future<void> _startLoading() async {
    _loadContent();
  }

  @override
  void dispose() {
    playerProvider.removeListener(_onPlayerChanged);
    _animController.dispose();
    super.dispose();
  }

  void _onPlayerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadContent() async {
    _loadTracks();
    _loadAlbums();
    _loadPlaylists();
    _loadRelated();
  }

  Future<void> _loadTracks() async {
    setState(() => _isLoadingTracks = true);
    final tracks = await SearchService.getArtistSongs(widget.title, limit: 80);
    if (mounted) {
      setState(() {
        _tracks = tracks;
        _isLoadingTracks = false;
      });
    }
  }

  Future<void> _loadAlbums() async {
    setState(() => _isLoadingAlbums = true);
    final results = await SearchService.search(
      '${widget.title} album',
      filter: SearchFilter.all,
      limit: 20,
    );
    final albums = results.where((r) => r.type == 'album').toList();
    debugPrint('ArtistDetail "${widget.title}": all=${results.length} albums=${albums.length} types=${results.map((r) => r.type).toSet()}');
    if (mounted) {
      setState(() {
        _albums = albums.take(5).toList();
        _isLoadingAlbums = false;
      });
    }
  }

  Future<void> _loadPlaylists() async {
    setState(() => _isLoadingPlaylists = true);
    final results = await SearchService.search(
      '${widget.title} playlist',
      filter: SearchFilter.all,
      limit: 20,
    );
    final playlists = results.where((r) => r.type == 'playlist').toList();
    debugPrint('ArtistDetail "${widget.title}": all=${results.length} playlists=${playlists.length} types=${results.map((r) => r.type).toSet()}');
    if (mounted) {
      setState(() {
        _playlists = playlists.take(5).toList();
        _isLoadingPlaylists = false;
      });
    }
  }

  Future<void> _loadRelated() async {
    setState(() => _isLoadingRelated = true);
    final results = await SearchService.search(
      widget.title,
      filter: SearchFilter.all,
      limit: 30,
    );
    final related = results.where((r) => r.type == 'artist').toList();
    debugPrint('ArtistDetail "${widget.title}": related=${related.length} from ${results.length} results');
    if (mounted) {
      setState(() {
        _related = related.take(7).toList();
        _isLoadingRelated = false;
      });
    }
  }


  void _playTrack(SearchResult result) {
    if (result.videoId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrackDetailScreen(
          title: result.title,
          artist: result.subtitle,
          imageUrl: result.imageUrl,
          videoId: result.videoId,
        ),
      ),
    );
  }

  void _togglePlayPause() {
    playerProvider.togglePlay();
  }

  void _shareArtist() {
    Share.share('Écoute ${widget.title} sur Tunefy');
  }

  PopupMenuItem<String> _menuItem(IconData icon, String label, String value) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: MyColors.whiteColor, size: 22),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(fontFamily: 'AM', fontSize: 14, color: MyColors.whiteColor)),
        ],
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MyColors.darkGreyColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 32, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  _sheetItem(Icons.open_in_new, "Voir sur YouTube", () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ouverture YouTube...', style: TextStyle(fontFamily: 'AM')), backgroundColor: MyColors.darkGreyColor, duration: Duration(seconds: 1)),
                    );
                  }),
                  _sheetItem(Icons.favorite_border, 'Ajouter aux favoris', () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ajouté aux favoris', style: TextStyle(fontFamily: 'AM')), backgroundColor: MyColors.darkGreyColor, duration: Duration(seconds: 1)),
                    );
                  }),
                  _sheetItem(Icons.playlist_add, 'Ajouter à une playlist', () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ajouté à la playlist', style: TextStyle(fontFamily: 'AM')), backgroundColor: MyColors.darkGreyColor, duration: Duration(seconds: 1)),
                    );
                  }),
                  _sheetItem(Icons.share, 'Partager', () {
                    Navigator.pop(ctx);
                    _shareArtist();
                  }),
                  _sheetItem(Icons.person_add_outlined, 'Suivre', () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Suivi !', style: TextStyle(fontFamily: 'AM')), backgroundColor: MyColors.darkGreyColor, duration: Duration(seconds: 1)),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: MyColors.whiteColor, size: 22),
      title: Text(label, style: const TextStyle(fontFamily: 'AM', fontSize: 14, color: MyColors.whiteColor)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final expandedHeight = screenH * 0.48;

    return Scaffold(
      backgroundColor: MyColors.blackColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          alignment: AlignmentDirectional.bottomCenter,
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(screenW, expandedHeight),
                _buildActionButtons(),
                _buildPopulaireSection(screenW),
                _buildAlbumsSection(screenW),
                _buildPlaylistsSection(screenW),
                _buildRelatedSection(screenW),
                SliverPadding(padding: EdgeInsets.only(bottom: 140 + MediaQuery.of(context).padding.bottom)),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
              child: const BottomPlayer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(double screenW, double expandedHeight) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      backgroundColor: MyColors.blackColor,
      leading: GestureDetector(
        onTap: () { HapticService.tap(); Navigator.pop(context),
        behavior: HitTestBehavior.translucent,
        child: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.arrow_back_ios, color: MyColors.whiteColor, size: 20),
          ),
        ),
      ),
      actions: [
        Builder(
          builder: (ctx) => GestureDetector(
            onTap: () => _showMoreMenu(ctx),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Icon(Icons.more_vert, color: MyColors.whiteColor, size: 24),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1DB954),
                    Color(0xFF1AA34A),
                    Color(0xFF148A3D),
                    Color(0xFF121212),
                  ],
                  stops: [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 50),
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Artiste vérifié',
                      style: TextStyle(fontFamily: 'AM', fontSize: 10, color: MyColors.whiteColor, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'AB', fontSize: screenW * 0.07, color: MyColors.whiteColor, fontWeight: FontWeight.w900),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _isLoadingTracks ? 'Chargement...' : '${_tracks.length} titres · ${_totalDuration()}',
                    style: TextStyle(fontFamily: 'AM', fontSize: 12, color: MyColors.whiteColor.withValues(alpha: 0.8)),
                  ),
                ],
              ),
          ],
        ),
        titlePadding: const EdgeInsets.only(left: 48, bottom: 14),
        title: Text(
          widget.title,
          style: const TextStyle(
            fontFamily: 'AB',
            fontSize: 16,
            color: MyColors.whiteColor,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }



  Widget _buildActionButtons() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                HapticService.tap();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ajouté aux favoris',
                        style: TextStyle(fontFamily: 'AM')),
                    backgroundColor: MyColors.darkGreyColor,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: MyColors.whiteColor, width: 1),
                ),
                child: const Icon(
                  Icons.add,
                  color: MyColors.whiteColor,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                HapticService.tap();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Téléchargement...',
                        style: TextStyle(fontFamily: 'AM')),
                    backgroundColor: MyColors.darkGreyColor,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: const Icon(
                Icons.download_outlined,
                color: MyColors.lightGrey,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _shareArtist,
              child: const Icon(
                Icons.share_outlined,
                color: MyColors.lightGrey,
                size: 22,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _isShuffleOn = !_isShuffleOn),
              child: Icon(
                Icons.shuffle,
                color: _isShuffleOn ? const Color(0xFF1DB954) : MyColors.whiteColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: MyColors.greenColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: MyColors.blackColor,
                  size: 34,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopulaireSection(double screenW) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 8),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: const Text(
              'Populaire',
              style: TextStyle(
                fontFamily: 'AB',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: MyColors.whiteColor,
              ),
            ),
          ),
          ...List.generate(_tracks.length, (index) => _TrackTile(
                track: _tracks[index],
                index: index + 1,
                onTap: () => _playTrack(_tracks[index]),
                onMenuTap: () => _showTrackMenu(context, _tracks[index]),
              )),
        ]),
      ),
    );
  }

  Widget _buildAlbumsSection(double screenW) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 30, left: 16, bottom: 12),
            child: Text(
              'Albums',
              style: TextStyle(
                fontFamily: 'AB',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: MyColors.whiteColor,
              ),
            ),
          ),
          if (_isLoadingAlbums)
            const SizedBox(
              height: 140,
              child: Center(
                child: CircularProgressIndicator(color: MyColors.greenColor),
              ),
            )
          else
            SizedBox(
              height: screenW * 0.50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16),
                itemCount: _albums.length,
                itemBuilder: (context, index) {
                  final album = _albums[index];
                  return GestureDetector(
                    onTap: () {
                      HapticService.tap();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CollectionDetailScreen(
                            title: album.title,
                            imageUrl: album.imageUrl,
                            subtitle: album.subtitle,
                            browseId: album.browseId ?? album.id,
                            type: 'album',
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.only(right: screenW * 0.035),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: screenW * 0.35,
                            height: screenW * 0.35,
                            decoration: const BoxDecoration(
                              color: MyColors.darkGreyColor,
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: album.imageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: album.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => const Icon(
                                        Icons.album,
                                        color: MyColors.lightGrey,
                                        size: 40,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.album,
                                      color: MyColors.lightGrey,
                                      size: 40,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: screenW * 0.35,
                            child: Text(
                              album.title,
                              style: const TextStyle(
                                fontFamily: 'AB',
                                fontSize: 12,
                                color: MyColors.whiteColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(
                            width: screenW * 0.35,
                            child: Text(
                              album.subtitle,
                              style: const TextStyle(
                                fontFamily: 'AM',
                                fontSize: 11,
                                color: MyColors.lightGrey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaylistsSection(double screenW) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 30, left: 16, bottom: 12),
            child: Text(
              'Playlists',
              style: TextStyle(
                fontFamily: 'AB',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: MyColors.whiteColor,
              ),
            ),
          ),
          if (_isLoadingPlaylists)
            const SizedBox(
              height: 140,
              child: Center(
                child: CircularProgressIndicator(color: MyColors.greenColor),
              ),
            )
          else
            SizedBox(
              height: screenW * 0.54,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16),
                itemCount: _playlists.length,
                itemBuilder: (context, index) {
                  final pl = _playlists[index];
                  return GestureDetector(
                    onTap: () {
                      HapticService.tap();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CollectionDetailScreen(
                            title: pl.title,
                            imageUrl: pl.imageUrl,
                            subtitle: pl.subtitle,
                            browseId: pl.browseId ?? pl.id,
                            type: 'playlist',
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.only(right: screenW * 0.035),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: screenW * 0.38,
                            height: screenW * 0.38,
                            decoration: BoxDecoration(
                              color: MyColors.darkGreyColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: pl.imageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: pl.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => const Icon(
                                        Icons.queue_music,
                                        color: MyColors.lightGrey,
                                        size: 40,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.queue_music,
                                      color: MyColors.lightGrey,
                                      size: 40,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: screenW * 0.38,
                            child: Text(
                              pl.title,
                              style: const TextStyle(
                                fontFamily: 'AB',
                                fontSize: 12,
                                color: MyColors.whiteColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(
                            width: screenW * 0.38,
                            child: Text(
                              pl.subtitle,
                              style: const TextStyle(
                                fontFamily: 'AM',
                                fontSize: 11,
                                color: MyColors.lightGrey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRelatedSection(double screenW) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 30, left: 16, bottom: 12),
            child: Text(
              'Vous pourriez aimer',
              style: TextStyle(
                fontFamily: 'AB',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: MyColors.whiteColor,
              ),
            ),
          ),
          if (_isLoadingRelated)
            const SizedBox(
              height: 140,
              child: Center(
                child: CircularProgressIndicator(color: MyColors.greenColor),
              ),
            )
          else
            SizedBox(
              height: screenW * 0.48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16),
                itemCount: _related.length,
                itemBuilder: (context, index) {
                  final artist = _related[index];
                  return Padding(
                    padding: EdgeInsets.only(right: screenW * 0.035),
                    child: GestureDetector(
                      onTap: () {
                        HapticService.tap();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ArtistDetailScreen(
                              title: artist.title,
                              imageUrl: artist.imageUrl,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: screenW * 0.35,
                            height: screenW * 0.35,
                            decoration: const BoxDecoration(
                              color: MyColors.darkGreyColor,
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: artist.imageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: artist.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => const Icon(
                                        Icons.person,
                                        color: MyColors.lightGrey,
                                        size: 40,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      color: MyColors.lightGrey,
                                      size: 40,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: screenW * 0.35,
                            child: Text(
                              artist.title,
                              style: const TextStyle(
                                fontFamily: 'AB',
                                fontSize: 12,
                                color: MyColors.whiteColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(
                            width: 100,
                            child: Text(
                              'Artiste',
                              style: TextStyle(
                                fontFamily: 'AM',
                                fontSize: 11,
                                color: MyColors.lightGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showTrackMenu(BuildContext context, SearchResult trackResult) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MyColors.darkGreyColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 32, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  _sheetItem(Icons.open_in_new, "Voir sur YouTube", () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ouverture YouTube...', style: TextStyle(fontFamily: 'AM')), backgroundColor: MyColors.darkGreyColor, duration: Duration(seconds: 1)),
                    );
                  }),
                  _sheetItem(Icons.favorite_border, 'Ajouter aux titres likés', () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ajouté aux titres likés', style: TextStyle(fontFamily: 'AM')), backgroundColor: MyColors.darkGreyColor, duration: Duration(seconds: 1)),
                    );
                  }),
                  _sheetItem(Icons.visibility_off_outlined, 'Masquer de la playlist', () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Masqué de la playlist', style: TextStyle(fontFamily: 'AM')), backgroundColor: MyColors.darkGreyColor, duration: Duration(seconds: 1)),
                    );
                  }),
                  _sheetItem(Icons.queue_music, "Ajouter à la file d'attente", () {
                    Navigator.pop(ctx);
                    if (trackResult.videoId != null) {
                      final track = Track(videoId: trackResult.videoId, title: trackResult.title, artist: trackResult.subtitle, albumImage: trackResult.imageUrl);
                      playerProvider.addToQueue(track);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ajouté à la file d\'attente', style: TextStyle(fontFamily: 'AM')), backgroundColor: MyColors.darkGreyColor, duration: Duration(seconds: 1)),
                    );
                  }),
                  _sheetItem(Icons.format_list_numbered, "Accéder à la file d'attente", () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('File d\'attente', style: TextStyle(fontFamily: 'AM')), backgroundColor: MyColors.darkGreyColor, duration: Duration(seconds: 1)),
                    );
                  }),
                  _sheetItem(Icons.album, "Accéder à l'album", () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Accès à l\'album...', style: TextStyle(fontFamily: 'AM')), backgroundColor: MyColors.darkGreyColor, duration: Duration(seconds: 1)),
                    );
                  }),
                  _sheetItem(Icons.person_outline, 'Accéder aux artistes', () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Accès aux artistes...', style: TextStyle(fontFamily: 'AM')), backgroundColor: MyColors.darkGreyColor, duration: Duration(seconds: 1)),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  final SearchResult track;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onMenuTap;

  const _TrackTile({
    required this.track,
    required this.index,
    required this.onTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 16, right: 16),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: track.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: track.imageUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _placeholderImage(),
                    )
                  : _placeholderImage(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: const TextStyle(
                      fontFamily: 'AM',
                      fontSize: 15,
                      color: MyColors.whiteColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.subtitle,
                    style: const TextStyle(
                      fontFamily: 'AM',
                      fontSize: 12,
                      color: MyColors.lightGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (track.duration != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  track.duration!,
                  style: const TextStyle(
                    fontFamily: 'AM',
                    fontSize: 12,
                    color: MyColors.lightGrey,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onMenuTap,
              child: const Icon(
                Icons.more_vert,
                color: MyColors.lightGrey,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 48,
      height: 48,
      color: MyColors.darkGreyColor,
      child: const Icon(
        Icons.music_note,
        color: MyColors.whiteColor,
        size: 20,
      ),
    );
  }
}
