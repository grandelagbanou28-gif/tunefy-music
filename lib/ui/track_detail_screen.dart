import 'package:flutter/material.dart';
import 'package:tunefy/DI/service_locator.dart';
import 'package:tunefy/models/track.dart';
import 'package:tunefy/services/liked_service.dart';
import 'package:tunefy/helpers/tunefy_helpers.dart';
import 'package:tunefy/widgets/add_to_playlist_sheet.dart';
import 'package:tunefy/widgets/share_modal.dart';
import 'package:tunefy/services/haptic_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:just_audio/just_audio.dart';

class TrackDetailScreen extends StatefulWidget {
  final String title;
  final String artist;
  final String? imageUrl;
  final String? videoId;

  const TrackDetailScreen({
    super.key,
    required this.title,
    required this.artist,
    this.imageUrl,
    this.videoId,
  });

  @override
  State<TrackDetailScreen> createState() => _TrackDetailScreenState();
}

class _TrackDetailScreenState extends State<TrackDetailScreen>
    with SingleTickerProviderStateMixin {
  final LikedService _likedService = LikedService();
  bool _isHeaderReady = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  bool _isLiked = false;
  bool _isShuffle = false;
  LoopMode _loopMode = LoopMode.off;

  @override
  void initState() {
    super.initState();
    _isLiked = _likedService.isLiked(widget.videoId);
    _isShuffle = playerProvider.player.shuffleModeEnabled;
    _loopMode = playerProvider.player.loopMode;
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
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() => _isHeaderReady = true);
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Track _toTrack() => Track(
    videoId: widget.videoId,
    title: widget.title,
    artist: widget.artist,
    albumImage: widget.imageUrl,
  );

  HomeTrack _toHomeTrack() => HomeTrack(
    videoId: widget.videoId ?? '',
    title: widget.title,
    artist: widget.artist,
    duration: '0:00',
    imageUrl: widget.imageUrl,
  );

  bool get _isThisTrackPlaying {
    final active = globalActiveTrack.value;
    return active != null && active.videoId == widget.videoId;
  }

  void _playThisTrack() {
    HapticService.tap();
    selectTrack(_toHomeTrack());
  }

  void _togglePlayPause() {
    HapticService.tap();
    if (_isThisTrackPlaying) {
      toggleGlobalPlay();
    } else {
      _playThisTrack();
    }
  }

  void _toggleShuffle() {
    HapticService.tap();
    setState(() => _isShuffle = !_isShuffle);
    playerProvider.player.setShuffleModeEnabled(_isShuffle);
  }

  void _toggleRepeat() {
    HapticService.tap();
    setState(() {
      switch (_loopMode) {
        case LoopMode.off:
          _loopMode = LoopMode.one;
          break;
        case LoopMode.one:
          _loopMode = LoopMode.all;
          break;
        case LoopMode.all:
          _loopMode = LoopMode.off;
          break;
      }
    });
    playerProvider.player.setLoopMode(_loopMode);
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: widget.imageUrl != null
                        ? CachedNetworkImage(imageUrl: widget.imageUrl!, width: 48, height: 48, fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(width: 48, height: 48, color: const Color(0xFF282828), child: const Icon(Icons.music_note, color: Color(0xFFB3B3B3), size: 22)))
                        : Container(width: 48, height: 48, color: const Color(0xFF282828), child: const Icon(Icons.music_note, color: Color(0xFFB3B3B3), size: 22)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: const TextStyle(fontFamily: 'AB', fontSize: 15, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(widget.artist, style: const TextStyle(fontFamily: 'AM', fontSize: 12, color: Color(0xFFB3B3B3))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF282828), height: 1),
            _menuItem(Icons.playlist_add, 'Ajouter à la playlist', () {
              Navigator.pop(ctx);
              Future.microtask(() => AddToPlaylistSheet.show(context, _toTrack()));
            }),
            _menuItem(Icons.favorite_border, _isLiked ? 'Retirer des Titres likés' : 'Ajouter aux Titres likés', () {
              Navigator.pop(ctx);
              _likedService.toggle(_toTrack());
              setState(() => _isLiked = _likedService.isLiked(widget.videoId));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isLiked ? 'Ajouté aux Titres likés' : 'Retiré des Titres likés', style: const TextStyle(fontFamily: 'AM')),
                  backgroundColor: const Color(0xFF282828),
                  duration: const Duration(seconds: 2),
                ),
              );
            }),
            _menuItem(Icons.queue_music, "Ajouter à la file d'attente", () {
              Navigator.pop(ctx);
              playerProvider.addToQueue(_toTrack());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Ajouté à la file d'attente", style: TextStyle(fontFamily: 'AM')), backgroundColor: Color(0xFF282828), duration: Duration(seconds: 2)),
              );
            }),
            const Divider(color: Color(0xFF282828), height: 1),
            _menuItem(Icons.share_outlined, 'Partager', () {
              Navigator.pop(ctx);
              Future.microtask(() {
                Share.share('${widget.title} - ${widget.artist}');
              });
            }),
            _menuItem(Icons.visibility_off_outlined, 'Masquer ce son', () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Son masqué', style: TextStyle(fontFamily: 'AM')), backgroundColor: Color(0xFF282828), duration: Duration(seconds: 2)),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap, {String? badge}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 22),
      title: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontFamily: 'AM', fontSize: 14, color: Colors.white)),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(badge,
                style: const TextStyle(fontFamily: 'AM', fontSize: 10, color: Colors.black, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes;
    final sec = d.inSeconds.remainder(60);
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isHeaderReady) {
      return Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF1DB954)),
        ),
      );
    }

    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final topBarH = safeTop + 48;
    final availableH = screenH - safeBottom - topBarH;
    final artSize = (screenW * 0.78).clamp(200.0, availableH * 0.85);

    return ListenableBuilder(
      listenable: playerProvider,
      builder: (context, _) {
        final pp = playerProvider;
        final isPlayingThis = _isThisTrackPlaying;
        final position = isPlayingThis ? pp.position : Duration.zero;
        final duration = isPlayingThis ? pp.duration : Duration.zero;
        final durationMs = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;

        return Scaffold(
          backgroundColor: const Color(0xFF000000),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Container(
                  height: topBarH,
                  padding: EdgeInsets.only(top: safeTop),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () { HapticService.tap(); Navigator.pop(context); },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Icon(Icons.chevron_left, color: Colors.white, size: 28),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _showMenu,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Icon(Icons.more_vert, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: safeBottom),
                    child: Column(
                      children: [
                        Container(
                          height: availableH * 0.5,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF121212), Color(0xFF000000)],
                              stops: [0.0, 0.6],
                            ),
                          ),
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: artSize,
                              height: artSize,
                              decoration: BoxDecoration(
                                color: const Color(0xFF282828),
                                borderRadius: BorderRadius.circular(isPlayingThis ? 50 : 12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 25,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(isPlayingThis ? 50 : 12),
                                child: widget.imageUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: widget.imageUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => const Center(
                                          child: Icon(Icons.music_note, color: Color(0xFFB3B3B3), size: 48),
                                        ),
                                        errorWidget: (_, __, ___) => const Center(
                                          child: Icon(Icons.music_note, color: Color(0xFFB3B3B3), size: 48),
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(Icons.music_note, color: Color(0xFFB3B3B3), size: 48),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(widget.title, style: const TextStyle(fontFamily: 'AB', fontSize: 22, color: Colors.white, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text(widget.artist, style: const TextStyle(fontFamily: 'AM', fontSize: 15, color: Color(0xFFB3B3B3))),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      HapticService.tap();
                                      _likedService.toggle(_toTrack());
                                      setState(() => _isLiked = _likedService.isLiked(widget.videoId));
                                    },
                                    child: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? const Color(0xFF1DB954) : const Color(0xFFB3B3B3), size: 28),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
                                child: Slider(
                                  value: position.inMilliseconds.toDouble().clamp(0.0, durationMs),
                                  max: durationMs,
                                  onChanged: (isPlayingThis && duration.inMilliseconds > 0)
                                      ? (v) => pp.seek(Duration(milliseconds: v.toInt()))
                                      : null,
                                  activeColor: Colors.white,
                                  inactiveColor: const Color(0xFF535353),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatDuration(position), style: TextStyle(fontFamily: 'AM', fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
                                  Text(_formatDuration(duration), style: TextStyle(fontFamily: 'AM', fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  GestureDetector(
                                    onTap: _toggleShuffle,
                                    child: Icon(Icons.shuffle, color: _isShuffle ? const Color(0xFF1DB954) : const Color(0xFFB3B3B3), size: 24),
                                  ),
                                  GestureDetector(
                                    onTap: () { HapticService.tap(); pp.skipToPrevious(); },
                                    child: const Icon(Icons.skip_previous, color: Colors.white, size: 32),
                                  ),
                                  GestureDetector(
                                    onTap: _togglePlayPause,
                                    child: Container(
                                      width: 64, height: 64,
                                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                      child: Icon(
                                        (isPlayingThis && pp.isPlaying) ? Icons.pause : Icons.play_arrow,
                                        color: Colors.black,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () { HapticService.tap(); pp.skipToNext(); },
                                    child: const Icon(Icons.skip_next, color: Colors.white, size: 32),
                                  ),
                                  GestureDetector(
                                    onTap: _toggleRepeat,
                                    child: Icon(
                                      _loopMode == LoopMode.one ? Icons.repeat_one : Icons.repeat,
                                      color: _loopMode != LoopMode.off ? const Color(0xFF1DB954) : const Color(0xFFB3B3B3),
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(Icons.devices, color: Color(0xFFB3B3B3), size: 20),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          HapticService.tap();
                                          Share.share('${widget.title} - ${widget.artist}');
                                        },
                                        child: const Icon(Icons.share_outlined, color: Color(0xFFB3B3B3), size: 20),
                                      ),
                                      const SizedBox(width: 20),
                                      GestureDetector(onTap: _showMenu, child: const Icon(Icons.more_vert, color: Color(0xFFB3B3B3), size: 20)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
