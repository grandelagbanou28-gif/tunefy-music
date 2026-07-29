import 'dart:math';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tunefy/services/search_service.dart';
import 'package:tunefy/DI/service_locator.dart';
import 'package:tunefy/models/track.dart';
import 'package:tunefy/ui/track_detail_screen.dart';
import 'package:tunefy/widgets/bottom_player.dart';
import 'package:tunefy/widgets/share_modal.dart';
import 'package:tunefy/services/haptic_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tunefy/theme/tunefy_theme.dart';

class CollectionDetailScreen extends StatefulWidget {
  final String title;
  final String? imageUrl;
  final String? subtitle;
  final String browseId;
  final String type;

  const CollectionDetailScreen({
    super.key,
    required this.title,
    this.imageUrl,
    this.subtitle,
    required this.browseId,
    required this.type,
  });

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen>
    with SingleTickerProviderStateMixin {
  List<SearchResult> _tracks = [];
  bool _isLoading = true;
  bool _isShuffleOn = false;
  bool _isHeaderReady = false;
  bool _isSaved = false;
  Color _headerColor = const Color(0xFF1E1E1E);
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  bool get _isAlbum => widget.type == 'album';

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
    _startLoading();
  }

  Future<void> _startLoading() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _isHeaderReady = true);
    _animController.forward();
    _loadTracks();
    _extractColor();
  }

  Future<void> _extractColor() async {
    if (widget.imageUrl == null) return;
    try {
      final cs = await ColorScheme.fromImageProvider(
        provider: NetworkImage(widget.imageUrl!),
        brightness: Brightness.dark,
      );
      if (!mounted) return;
      setState(() => _headerColor = cs.primary.withValues(alpha: 0.7));
    } catch (_) {}
  }

  Future<void> _loadTracks() async {
    setState(() => _isLoading = true);
    final tracks = await SearchService.browseAlbumOrPlaylist(widget.browseId);
    if (mounted) {
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<Track> get _validTracks =>
      _tracks.where((r) => r.videoId != null).map((r) => Track(
        videoId: r.videoId,
        title: r.title,
        artist: r.subtitle,
        albumImage: r.imageUrl,
      )).toList();

  int get _totalSeconds {
    int s = 0;
    for (final t in _tracks) {
      if (t.duration != null && t.duration!.isNotEmpty) {
        final parts = t.duration!.split(':');
        if (parts.length == 2) s += int.tryParse(parts[0])! * 60 + int.tryParse(parts[1])!;
      }
    }
    return s;
  }

  String get _durationLabel {
    final h = _totalSeconds ~/ 3600;
    final m = (_totalSeconds % 3600) ~/ 60;
    if (h > 0) return '$h h $m min';
    return '$m min';
  }

  void _playTrackAt(int index) {
    if (_tracks.isEmpty || index < 0 || index >= _tracks.length) return;
    final result = _tracks[index];
    Navigator.push(context, tunefyRoute(TrackDetailScreen(
      title: result.title, artist: result.subtitle, imageUrl: result.imageUrl, videoId: result.videoId,)));
  }

  void _playAll() {
    if (_validTracks.isEmpty) return;
    final all = _isShuffleOn ? (List<Track>.from(_validTracks)..shuffle()) : _validTracks;
    playerProvider.playTrack(all.first, all);
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            _menuTile(Icons.share_outlined, 'Partager', () { Navigator.pop(ctx); Share.share(widget.title); }),
            _menuTile(Icons.library_add_outlined, _isSaved ? 'Retirer de la Bibliothèque' : 'Ajouter à la Bibliothèque', () {
              Navigator.pop(ctx);
              setState(() => _isSaved = !_isSaved);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(_isSaved ? 'Ajouté à la Bibliothèque' : 'Retiré de la Bibliothèque', style: const TextStyle(fontFamily: 'AM')),
                backgroundColor: const Color(0xFF282828), duration: const Duration(seconds: 2),
              ));
            }),
            _menuTile(Icons.download_outlined, 'Télécharger', () { Navigator.pop(ctx); }, badge: 'Premium'),
            _menuTile(Icons.playlist_add, 'Ajouter à une playlist', () { Navigator.pop(ctx); }),
            const Divider(color: Color(0xFF282828), height: 1),
            _menuTile(Icons.person_outline, 'Voir les artistes', () { Navigator.pop(ctx); }),
            _menuTile(Icons.radio_outlined, 'Aller à la radio', () { Navigator.pop(ctx); }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(IconData icon, String label, VoidCallback onTap, {String? badge}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 22),
      title: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontFamily: 'AM', fontSize: 14, color: Colors.white))),
          if (badge != null) Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFF1DB954), borderRadius: BorderRadius.circular(4)),
            child: Text(badge, style: const TextStyle(fontFamily: 'AM', fontSize: 10, color: Colors.black, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final isLandscape = screenW > screenH;

    if (!_isHeaderReady) {
      return Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954))),
      );
    }

    final artSize = min(screenW * 0.65, (screenH - safeTop - safeBottom) * 0.35).clamp(120.0, 260.0);
    final topAreaH = safeTop + (isLandscape ? 120.0 : screenW * 0.75);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeader(screenW, topAreaH, artSize),
                _buildActionBar(),
                if (!_isLoading && _tracks.isNotEmpty) _buildTracksInfo(),
                if (_isLoading) const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF1DB954))))
                else if (_tracks.isEmpty)
                  const SliverFillRemaining(child: Center(child: Text('Aucune piste trouvée', style: TextStyle(fontFamily: 'AM', fontSize: 14, color: Color(0xFFB3B3B3)))))
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final track = _tracks[index];
                        return _TrackTile(
                          track: track, index: index + 1,
                          onTap: () => _playTrackAt(index),
                          onMenuTap: () => _showTrackMenu(track),
                        );
                      }, childCount: _tracks.length),
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 140)),
                ],
              ],
            ),
            const Positioned(bottom: 64, left: 0, right: 0, child: BottomPlayer()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double screenW, double topAreaH, double artSize) {
    return SliverToBoxAdapter(
      child: Container(
        height: topAreaH,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_headerColor, const Color(0xFF000000)],
            stops: const [0.0, 0.85],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).padding.top + 4, left: 0, right: 0,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () { HapticService.tap(); Navigator.pop(context),
                    child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.chevron_left, color: Colors.white, size: 28)),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showMenu,
                    child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.more_vert, color: Colors.white, size: 24)),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16, bottom: 0, right: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: artSize,
                      height: artSize,
                      color: const Color(0xFF282828),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (widget.imageUrl != null)
                            CachedNetworkImage(
                              imageUrl: widget.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const Center(child: Icon(Icons.music_note, color: Color(0xFFB3B3B3), size: 36)),
                              errorWidget: (_, __, ___) => const Center(child: Icon(Icons.music_note, color: Color(0xFFB3B3B3), size: 36)),
                            )
                          else
                            const Center(child: Icon(Icons.music_note, color: Color(0xFFB3B3B3), size: 36)),
                          Positioned(
                            bottom: 6, left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1DB954),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Tunefy', style: TextStyle(fontFamily: 'AB', fontSize: 8, color: Colors.black, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: _isAlbum ? Colors.orange.withValues(alpha: 0.9) : const Color(0xFF1DB954).withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(_isAlbum ? 'Album' : 'Playlist', style: const TextStyle(fontFamily: 'AM', fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(height: 8),
                          Text(widget.title, style: TextStyle(fontFamily: 'AB', fontSize: screenW * 0.055, color: Colors.white, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                          if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(widget.subtitle!, style: const TextStyle(fontFamily: 'AM', fontSize: 12, color: Color(0xFFB3B3B3)), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                          const SizedBox(height: 4),
                          const Text('Conçu spécialement pour vous', style: TextStyle(fontFamily: 'AM', fontSize: 11, color: Color(0xFF1DB954))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    final hasTracks = _tracks.isNotEmpty && !_isLoading;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                HapticService.tap();
                setState(() => _isSaved = !_isSaved);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(_isSaved ? 'Ajouté à la Bibliothèque' : 'Retiré de la Bibliothèque', style: const TextStyle(fontFamily: 'AM')),
                  backgroundColor: const Color(0xFF282828), duration: const Duration(seconds: 2),
                ));
              },
              child: AnimatedSwitcher(duration: const Duration(milliseconds: 200),
                child: _isSaved
                    ? const Icon(Icons.check_circle, key: ValueKey('check'), color: Color(0xFF1DB954), size: 28)
                    : const Icon(Icons.add_circle_outline, key: ValueKey('plus'), color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              child: const Icon(Icons.download_outlined, color: Colors.white, size: 26),
              onTap: () { HapticService.tap(); ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Téléchargement...', style: TextStyle(fontFamily: 'AM')), backgroundColor: Color(0xFF282828), duration: Duration(seconds: 2)),
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => _showShareModal(),
              child: const Icon(Icons.share_outlined, color: Colors.white, size: 26),
            ),
            const Spacer(),
            if (hasTracks) ...[
              GestureDetector(
                onTap: () => setState(() => _isShuffleOn = !_isShuffleOn),
                child: Icon(Icons.shuffle, color: _isShuffleOn ? const Color(0xFF1DB954) : Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _playAll,
                child: Container(
                  width: 52, height: 52,
                  decoration: const BoxDecoration(color: Color(0xFF1DB954), shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 30),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTracksInfo() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          '${_tracks.length} titres · $_durationLabel',
          style: const TextStyle(fontFamily: 'AM', fontSize: 13, color: Color(0xFFB3B3B3), fontWeight: FontWeight.w400),
        ),
      ),
    );
  }

  void _showShareModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ShareModal(
        title: widget.title,
        artist: widget.subtitle ?? '',
        imageUrl: widget.imageUrl,
      ),
    );
  }

  void _showTrackMenu(SearchResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            if (result.imageUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(4), child: CachedNetworkImage(imageUrl: result.imageUrl!, width: 40, height: 40, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(width: 40, height: 40, color: const Color(0xFF000000), child: const Icon(Icons.music_note, color: Color(0xFFB3B3B3), size: 18)))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(result.title, style: const TextStyle(fontFamily: 'AB', fontSize: 14, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(result.subtitle, style: const TextStyle(fontFamily: 'AM', fontSize: 12, color: Color(0xFFB3B3B3)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF282828), height: 1),
            _menuTile(Icons.favorite_border, 'Ajouter aux titres likés', () { Navigator.pop(ctx); }),
            _menuTile(Icons.playlist_add, 'Ajouter à la playlist', () { Navigator.pop(ctx); }),
            _menuTile(Icons.visibility_off_outlined, 'Masquer de la playlist', () { Navigator.pop(ctx); }),
            _menuTile(Icons.queue_music, "Ajouter à la file d'attente", () {
              Navigator.pop(ctx);
              if (result.videoId != null) {
                playerProvider.addToQueue(Track(videoId: result.videoId, title: result.title, artist: result.subtitle, albumImage: result.imageUrl));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ajouté à la file d'attente", style: TextStyle(fontFamily: 'AM')), backgroundColor: Color(0xFF282828), duration: Duration(seconds: 2)));
              }
            }),
            _menuTile(Icons.person_outline, 'Accéder aux artistes', () { Navigator.pop(ctx); }),
            _menuTile(Icons.album_outlined, "Accéder à l'album", () { Navigator.pop(ctx); }),
            _menuTile(Icons.share_outlined, 'Partager', () { Navigator.pop(ctx); Share.share('${result.title} - ${result.subtitle}'); }),
            const SizedBox(height: 8),
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

  const _TrackTile({required this.track, required this.index, required this.onTap, required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            SizedBox(width: 24, child: Text('$index', style: const TextStyle(fontFamily: 'AM', fontSize: 14, color: Color(0xFFB3B3B3)), textAlign: TextAlign.center)),
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: track.imageUrl != null
                  ? CachedNetworkImage(imageUrl: track.imageUrl!, width: 48, height: 48, fit: BoxFit.cover, errorWidget: (_, __, ___) => _ph())
                  : _ph(),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(track.title, style: const TextStyle(fontFamily: 'AM', fontSize: 15, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(track.subtitle, style: const TextStyle(fontFamily: 'AM', fontSize: 12, color: Color(0xFFB3B3B3)), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            if (track.duration != null && track.duration!.isNotEmpty) Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(track.duration!, style: const TextStyle(fontFamily: 'AM', fontSize: 12, color: Color(0xFFB3B3B3))),
            ),
            GestureDetector(
              onTap: onMenuTap,
              child: const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.more_vert, color: Color(0xFFB3B3B3), size: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ph() => Container(width: 48, height: 48, color: const Color(0xFF282828), child: const Icon(Icons.music_note, color: Colors.white, size: 20));
}
