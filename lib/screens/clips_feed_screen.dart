import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/providers/clips_provider.dart';
import 'package:muzo/providers/player_provider.dart';
import 'package:muzo/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// TikTok-style vertical clips feed: full-screen swipeable music videos with
/// like / dislike / download actions. Real video streams (360p muxed) play
/// inline; when a stream cannot be opened the clip falls back to its cover
/// art with the audio running through the normal player.
class ClipsFeedScreen extends ConsumerStatefulWidget {
  const ClipsFeedScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<ClipsFeedScreen> createState() => _ClipsFeedScreenState();
}

class _ClipsFeedScreenState extends ConsumerState<ClipsFeedScreen> {
  late final PageController _controller;
  final ScrollController _dotsScrollController = ScrollController();
  ClipPageController? _active;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _currentPage = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _active?.dispose();
    _controller.dispose();
    _dotsScrollController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _activate(int index, List<MuzoItem> clips) {
    if (index < 0 || index >= clips.length) return;
    final item = clips[index];
    if (_active?.videoId == item.videoId) return;
    _active?.dispose();
    _active = ClipPageController(
      item: item,
      handlerPlayer: ref.read(audioHandlerProvider).player,
    )..start();
    ref.read(audioHandlerProvider).playVideo(item, isClip: true);
  }

  void _scrollDotsToIndex(int index) {
    if (!_dotsScrollController.hasClients) return;
    final target = (index * 18.0) - 80.0;
    _dotsScrollController.animateTo(
      target.clamp(0.0, _dotsScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  bool _activatedInitial = false;

  @override
  Widget build(BuildContext context) {
    final clipsAsync = ref.watch(clipsFeedProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: clipsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF1DDA63)),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Impossible de charger les clips',
                  style: TextStyle(color: Colors.white.withValues(alpha: .8))),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.read(clipsFeedProvider.notifier).loadMore(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (clips) {
          if (clips.isEmpty) {
            return const Center(
              child: Text('Aucun clip pour le moment',
                  style: TextStyle(color: Colors.white70)),
            );
          }
          if (!_activatedInitial) {
            _activatedInitial = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _activate(widget.initialIndex, clips);
            });
          }
          return Stack(
            children: [
              PageView.builder(
                controller: _controller,
                scrollDirection: Axis.vertical,
                itemCount: clips.length,
                onPageChanged: (i) {
                  HapticFeedback.lightImpact();
                  setState(() => _currentPage = i);
                  _activate(i, clips);
                  _scrollDotsToIndex(i);
                  ref.read(clipsFeedProvider.notifier).onPageChanged(i);
                },
                itemBuilder: (context, i) {
                  return _ClipPage(
                    key: ValueKey(clips[i].videoId),
                    item: clips[i],
                    activeController: _active,
                    isActive: _active?.videoId == clips[i].videoId,
                  );
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 80,
                child: SizedBox(
                  height: 20,
                  child: ListView.builder(
                    controller: _dotsScrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: clips.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, i) {
                      final active = i == _currentPage;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _controller.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: active ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Owns one page's video playback. The video track is MUTED — all audio runs
/// through the global audio handler so the mini player reflects the clip and
/// sound keeps playing after leaving the feed. Falls back silently to
/// cover-art mode when a stream cannot be opened.
class ClipPageController {
  ClipPageController({required this.item, required this.handlerPlayer})
      : videoId = item.videoId;

  final MuzoItem item;
  final String? videoId;
  final dynamic handlerPlayer;
  VideoPlayerController? _player;
  StreamSubscription<bool>? _playingSub;
  Timer? _fallbackTimer;
  bool disposed = false;

  Future<void> start() async {
    try {
      final url = await resolveVideoUrl(item.videoId!);
      if (url == null || disposed) return;
      final vc = VideoPlayerController.networkUrl(Uri.parse(url));
      _player = vc;
      await vc.initialize();
      if (disposed) {
        await vc.dispose();
        return;
      }
      await vc.setLooping(true);
      await vc.setVolume(0); // audio comes from the audio handler
      // Mirror the handler's play state (tap-to-pause keeps A/V in sync and
      // pausing music elsewhere pauses the clip too).
      _playingSub = handlerPlayer.playingStream.listen((playing) {
        if (disposed) return;
        playing ? _player?.play() : _player?.pause();
      });
      if (handlerPlayer.player.playing) {
        await vc.play();
      }
      // If the handler audio is very slow (e.g. YouTube bot-check), give it
      // a grace period and then fall back to the video's own audio so the
      // clip is never completely silent.
      _fallbackTimer = Timer(const Duration(seconds: 6), () async {
        if (disposed) return;
        final state = handlerPlayer.processingState;
        if (state == ProcessingState.ready || state == ProcessingState.buffering) {
          return; // handler audio is alive
        }
        debugPrint('ClipPageController: handler audio slow — unmuting video');
        try {
          await _player?.setVolume(1.0);
          if (handlerPlayer.player.playing) await _player?.play();
        } catch (_) {}
      });
    } catch (_) {
      // Cover-art fallback keeps the feed usable.
      _player = null;
    }
  }

  static final YoutubeExplode _yt = YoutubeExplode();

  /// Best muxed stream URL under a sane size cap, else lowest videoOnly.
  static Future<String?> resolveVideoUrl(String videoId,
      {int capMb = 45}) async {
    try {
      final manifest =
          await _yt.videos.streamsClient.getManifest(videoId).timeout(const Duration(seconds: 12));
      // Prefer a small-ish muxed stream (plays everywhere): largest one
      // still under a sane size cap so quality stays decent on mobile data.
      final muxed = manifest.muxed.toList()
        ..sort((a, b) => a.size.totalBytes.compareTo(b.size.totalBytes));
      final cap = capMb * 1024 * 1024;
      if (muxed.isNotEmpty) {
        AudioStreamInfo? best;
        for (final s in muxed) {
          if (s.size.totalBytes <= cap) best = s;
        }
        return (best ?? muxed.first).url.toString();
      }
      final videoOnly = manifest.videoOnly.toList()
        ..sort((a, b) => a.size.totalBytes.compareTo(b.size.totalBytes));
      if (videoOnly.isNotEmpty) return videoOnly.first.url.toString();
    } catch (_) {
      return null;
    }
    return null;
  }

  void dispose() {
    disposed = true;
    _fallbackTimer?.cancel();
    _playingSub?.cancel();
    _player?.pause();
    _player?.dispose();
    _player = null;
  }
}

/// Like / dislike persistence for clips (separate from favorites).
class ClipReactions {
  static Future<Set<String>> _load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(key) ?? <String>[]).toSet();
  }

  static Future<bool> isLiked(String id) async => (await _load('clip_liked')).contains(id);
  static Future<bool> isDisliked(String id) async =>
      (await _load('clip_disliked')).contains(id);

  static Future<void> toggleLike(String id) => _toggle('clip_liked', 'clip_disliked', id);
  static Future<void> toggleDislike(String id) => _toggle('clip_disliked', 'clip_liked', id);

  static Future<void> _toggle(String key, String opposite, String id) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(key) ?? <String>[]).toSet();
    final other = (prefs.getStringList(opposite) ?? <String>[]).toSet()..remove(id);
    if (!set.remove(id)) set.add(id);
    await prefs.setStringList(key, set.toList());
    await prefs.setStringList(opposite, other.toList());
  }
}

class _ClipPage extends ConsumerStatefulWidget {
  const _ClipPage({
    super.key,
    required this.item,
    required this.activeController,
    required this.isActive,
  });

  final MuzoItem item;
  final ClipPageController? activeController;
  final bool isActive;

  @override
  ConsumerState<_ClipPage> createState() => _ClipPageState();
}

class _ClipPageState extends ConsumerState<_ClipPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _kenBurns = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat(reverse: true);

  bool? _liked;
  bool? _disliked;

  @override
  void initState() {
    super.initState();
    _loadReactions();
  }

  Future<void> _loadReactions() async {
    final id = widget.item.videoId!;
    _liked = await ClipReactions.isLiked(id);
    _disliked = await ClipReactions.isDisliked(id);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _kenBurns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final thumb = item.thumbnails.isNotEmpty ? item.thumbnails.last.url : '';
    final video = widget.activeController?._player;
    final hasVideo = widget.isActive && video != null && video.value.isInitialized;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ─── Visual layer ───
        if (hasVideo)
          Center(
            child: AspectRatio(
              aspectRatio: video!.value.aspectRatio,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: video.value.size.width,
                  height: video.value.size.height,
                  child: VideoPlayer(video),
                ),
              ),
            ),
          )
        else
          AnimatedBuilder(
            animation: _kenBurns,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(_kenBurns.value);
              return Transform.scale(
                scale: 1.0 + 0.08 * t,
                child: thumb.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: thumb,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: const Color(0xFF1A1A2E),
                          child: const Center(
                            child: Icon(Icons.music_note_rounded,
                                color: Color(0xFF1DDA63), size: 48),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFF1A1A2E),
                          child: const Center(
                            child: Icon(Icons.music_note_rounded,
                                color: Color(0xFF1DDA63), size: 48),
                          ),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF1A1A2E),
                        child: const Center(
                          child: Icon(Icons.music_note_rounded,
                              color: Color(0xFF1DDA63), size: 48),
                        ),
                      ),
              );
            },
          ),

        // ─── Gradients for legibility ───
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [Colors.black.withValues(alpha: .45), Colors.transparent],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [Colors.black.withValues(alpha: .65), Colors.transparent],
              ),
            ),
            child: const SizedBox(height: 320, width: double.infinity),
          ),
        ),

        // Tap toggles pause/play — the muted video mirrors the handler.
        // Double-tap left/right seeks backward/forward.
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              final handler = ref.read(audioHandlerProvider);
              if (handler.player.playing) {
                handler.pause();
              } else {
                handler.resume();
              }
            },
            onDoubleTapDown: (details) {
              final w = MediaQuery.of(context).size.width;
              final handler = ref.read(audioHandlerProvider);
              final pos = handler.player.position;
              final dur = handler.player.duration ?? Duration.zero;
              if (details.localPosition.dx < w / 2) {
                final target = pos - const Duration(seconds: 10);
                handler.seek(target < Duration.zero ? Duration.zero : target);
              } else {
                final target = pos + const Duration(seconds: 10);
                handler.seek(target > dur ? dur : target);
              }
              HapticFeedback.mediumImpact();
            },
          ),
        ),

        // ─── Right rail actions ───
        Positioned(
          right: 12,
          bottom: 140,
          child: Column(
            children: [
              _railAction(
                icon: (_liked ?? false)
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: (_liked ?? false) ? const Color(0xFFFE2C55) : Colors.white,
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await ClipReactions.toggleLike(item.videoId!);
                  _liked = await ClipReactions.isLiked(item.videoId!);
                  setState(() {});
                  if (_liked ?? false) {
                    try {
                      await ref.read(storageServiceProvider).toggleFavorite(item);
                    } catch (_) {}
                  }
                },
              ),
              const SizedBox(height: 18),
              _railAction(
                icon: (_disliked ?? false)
                    ? Icons.thumb_down_alt_rounded
                    : Icons.thumb_down_alt_outlined,
                color: (_disliked ?? false) ? const Color(0xFF2C6BFE) : Colors.white,
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await ClipReactions.toggleDislike(item.videoId!);
                  _disliked = await ClipReactions.isDisliked(item.videoId!);
                  setState(() {});
                },
              ),
              const SizedBox(height: 18),
              _DownloadRailButton(item: item),
            ],
          ),
        ),

        // ─── Bottom info ───
        Positioned(
          left: 16,
          right: 84,
          bottom: 48,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '@${item.displayArtist}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _railAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: 34),
    );
  }
}

/// Downloads the clip as a real VIDEO file and saves it to the device
/// Gallery (Movies/Tunefy). Progress is local to the button; completion is
/// persisted so the check mark survives restarts.
class _DownloadRailButton extends ConsumerStatefulWidget {
  const _DownloadRailButton({required this.item});

  final MuzoItem item;

  @override
  ConsumerState<_DownloadRailButton> createState() => _DownloadRailButtonState();
}

class _DownloadRailButtonState extends ConsumerState<_DownloadRailButton> {
  double? _progress;
  bool _done = false;
  bool _failed = false;
  static const _doneKey = 'clip_gallery_dl';

  @override
  void initState() {
    super.initState();
    _loadDone();
  }

  Future<void> _loadDone() async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_doneKey) ?? <String>[]);
    final id = widget.item.videoId;
    if (id != null && set.contains(id) && mounted) setState(() => _done = true);
  }

  Future<void> _download() async {
    final id = widget.item.videoId;
    if (id == null || _progress != null || _done) return;
    setState(() {
      _progress = 0.0;
      _failed = false;
    });
    try {
      final url = await ClipPageController.resolveVideoUrl(id, capMb: 90);
      if (url == null) throw Exception('stream unavailable');

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/tunefy_clip_$id.mp4';
      await Dio().download(
        url,
        path,
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
          },
        ),
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = (received / total).clamp(0.0, 0.95));
          }
        },
      );

      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }
      await Gal.putVideo(path, album: 'Tunefy');
      if (File(path).existsSync()) File(path).deleteSync();

      final prefs = await SharedPreferences.getInstance();
      final set = (prefs.getStringList(_doneKey) ?? <String>[])..add(id);
      await prefs.setStringList(_doneKey, set);

      if (mounted) {
        setState(() {
          _progress = null;
          _done = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _progress = null;
          _failed = true;
        });
        Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _failed = false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_progress != null || _done || _failed) return;
        HapticFeedback.lightImpact();
        unawaited(_download());
      },
      child: _progress != null
          ? SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: 3,
                color: const Color(0xFF1DDA63),
              ),
            )
          : Icon(
              _failed
                  ? Icons.error_outline_rounded
                  : _done
                      ? Icons.download_done_rounded
                      : Icons.download_rounded,
              color: _failed
                  ? Colors.redAccent
                  : _done
                      ? const Color(0xFF1DDA63)
                      : Colors.white,
              size: 32,
            ),
    );
  }
}
