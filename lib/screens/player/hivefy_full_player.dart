import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:widget_marquee/widget_marquee.dart';

import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/models/artist_details.dart';
import 'package:muzo/providers/player_provider.dart';
import 'package:muzo/providers/artist_bio_provider.dart';
import 'package:muzo/providers/download_provider.dart';
import 'package:muzo/providers/sleep_timer_provider.dart';
import 'package:muzo/services/storage_service.dart';
import 'package:muzo/services/lyrics_service.dart';
import 'package:muzo/services/muzo_api_service.dart';
import 'package:muzo/utils/app_colors.dart';
import 'package:muzo/widgets/hivefy_mini_player.dart';
import 'package:muzo/screens/lyrics_full_screen.dart';
import 'package:muzo/widgets/song_options_menu.dart';
import 'package:muzo/widgets/sleep_timer_dialog.dart';

class HivefyFullPlayer extends ConsumerStatefulWidget {
  const HivefyFullPlayer({super.key});

  @override
  ConsumerState<HivefyFullPlayer> createState() => _HivefyFullPlayerState();
}

class _HivefyFullPlayerState extends ConsumerState<HivefyFullPlayer> {
  final PageController _pageController = PageController();
  ArtistDetails? _artistDetails;
  bool _loadingArtist = false;
  Lyrics? _lyrics;
  bool _isLoadingLyrics = false;
  bool _biographyExpanded = false;
  StreamSubscription<int?>? _currentIndexSub;
  final ScrollController _lyricsScrollController = ScrollController();
  final List<GlobalKey> _lyricsLineKeys = [];
  int _lyricsActiveLine = -1;

  @override
  void initState() {
    super.initState();
    _updateBgColor();
    _fetchArtist();
    _listenCurrentIndex();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final item = ref.read(currentMediaItemProvider).valueOrNull;
      if (item != null) _fetchLyrics(item);
    });
  }

  @override
  void dispose() {
    _currentIndexSub?.cancel();
    _pageController.dispose();
    _lyricsScrollController.dispose();
    super.dispose();
  }

  /// Keep the album-art PageView in sync with the player's current index so
  /// that pausing, skipping or re-ordering the queue never leaves a stale
  /// album cover on screen.
  void _listenCurrentIndex() {
    final player = ref.read(audioHandlerProvider).player;
    _currentIndexSub = player.currentIndexStream.listen((index) {
      if (!mounted || index == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        final current = _pageController.page?.round();
        if (current != index) {
          try {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          } catch (_) {}
        }
      });
    });
  }

  Future<void> _updateBgColor() async {
    final mediaItem = ref.read(currentMediaItemProvider).valueOrNull;
    final url = mediaItem?.artUri?.toString() ?? '';
    if (url.isEmpty) return;
    try {
      final pi = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(url),
      );
      if (!mounted) return;
      final c = pi.dominantColor?.color ?? Colors.black;
      final hsl = HSLColor.fromColor(c);
      ref.read(playerColourProvider.notifier).state =
          hsl.withLightness((hsl.lightness * 0.35).clamp(0.0, 1.0)).toColor();
    } catch (_) {}
  }

  Future<void> _fetchArtist() async {
    final mediaItem = ref.read(currentMediaItemProvider).valueOrNull;
    if (mediaItem == null) return;
    final artistId = mediaItem.extras?['artistId'] as String?;
    if (_loadingArtist) return;
    _loadingArtist = true;
    try {
      final storage = ref.read(storageServiceProvider);
      final avatar = artistId != null && artistId.isNotEmpty
          ? storage.getArtistImage(artistId)
          : null;
      if (avatar != null &&
          avatar.isNotEmpty &&
          avatar != 'INVALID_ARTIST' &&
          mounted) {
        setState(() {
          _artistDetails = ArtistDetails(
            artistName: mediaItem.artist ?? '',
            artistAvatar: avatar,
            playlistId: '',
            recommendedArtists: const [],
            featuredOnPlaylists: const [],
          );
        });
      }
      final api = MuzoApiService(storage);
      final details = await api.getArtistDetails(artistId ?? '');
      if (mounted && details != null) {
        setState(() => _artistDetails = details);
        if (details.artistAvatar.isNotEmpty) {
          await storage.setArtistImage(artistId!, details.artistAvatar);
        }
      }
    } catch (_) {}
    _loadingArtist = false;
  }

  Future<void> _fetchLyrics(MediaItem mediaItem) async {
    if (_isLoadingLyrics) return;
    _isLoadingLyrics = true;
    try {
      final service = ref.read(lyricsServiceProvider);
      final lyrics = await service.fetchLyrics(
        mediaItem.title,
        mediaItem.artist ?? '',
        mediaItem.duration?.inSeconds ?? 0,
      );
      if (mounted) {
        setState(() {
          _lyrics = lyrics;
          _lyricsActiveLine = -1;
          if (_lyricsLineKeys.isNotEmpty) _lyricsLineKeys.clear();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _lyrics = null);
    }
    _isLoadingLyrics = false;
  }

  bool get _hasUsableLyrics {
    final l = _lyrics;
    if (l == null) return false;
    final timed = _parseSyncedLines(l);
    if (timed.isNotEmpty) return true;
    final plain = l.plainLyrics.trim();
    return plain
        .split('\n')
        .map((x) => x.trim())
        .where((x) => x.isNotEmpty)
        .isNotEmpty;
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  Widget _marqueeText(
    String text, {
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
    Color color = Colors.white,
    double letterSpacing = 0,
  }) {
    if (text.length <= 30) {
      return Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return SizedBox(
      height: fontSize * 1.3,
      child: Marquee(
        delay: const Duration(milliseconds: 300),
        duration: const Duration(seconds: 10),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            letterSpacing: letterSpacing,
          ),
        ),
      ),
    );
  }

  void _openQueueSheet() {
    final size = MediaQuery.of(context).size;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.01,
        maxChildSize: 0.95,
        expand: false,
        snap: true,
        builder: (_, scrollController) => Container(
          constraints: BoxConstraints(maxHeight: size.height, maxWidth: size.width),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.cardTranslucent, Colors.black87],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: SizedBox(
                  width: 40,
                  height: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white54,
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Queue",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Playing next",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ),
              Flexible(
                fit: FlexFit.tight,
                child: _buildQueueList(scrollController),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQueueList(ScrollController scrollController) {
    final audioHandler = ref.read(audioHandlerProvider);
    final player = audioHandler.player;

    return StreamBuilder<SequenceState?>(
      stream: player.sequenceStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final sequence = state?.sequence ?? [];
        final currentIndex = state?.currentIndex ?? 0;
        final nextItems = currentIndex + 1 < sequence.length
            ? sequence.sublist(currentIndex + 1)
            : [];

        if (nextItems.isEmpty) {
          return const Center(
            child: Text("No upcoming songs",
                style: TextStyle(color: Colors.white54, fontSize: 14)),
          );
        }

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: nextItems.length,
          itemBuilder: (context, index) {
            final item = nextItems[index].tag as MediaItem;
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: item.artUri?.toString() ?? '',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 40,
                    height: 40,
                    color: Colors.grey[800],
                    child: const Icon(Icons.music_note, color: Colors.white38, size: 18),
                  ),
                ),
              ),
              title: Text(item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              subtitle: Text(item.artist ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
              onTap: () {
                Navigator.of(context).pop();
                player.seek(Duration.zero, index: currentIndex + 1 + index);
                player.play();
              },
            );
          },
        );
      },
    );
  }

  MuzoItem _buildMuzoItemFromMedia(MediaItem mediaItem) {
    return MuzoItem(
      videoId: mediaItem.id,
      title: mediaItem.title,
      resultType: mediaItem.extras?['resultType'] ?? 'video',
      isExplicit: false,
      artists: [MuzoArtist(name: mediaItem.artist ?? '', id: mediaItem.extras?['artistId'])],
      thumbnails: mediaItem.artUri != null
          ? [MuzoThumbnail(url: mediaItem.artUri.toString(), width: 0, height: 0)]
          : [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaItem = ref.watch(currentMediaItemProvider).valueOrNull;
    final audioHandler = ref.watch(audioHandlerProvider);
    final player = audioHandler.player;
    final storage = ref.watch(storageServiceProvider);
    final downloadState = ref.watch(downloadProvider);

    if (mediaItem == null) {
      return const SizedBox.shrink();
    }

    final isLiked = storage.isFavorite(mediaItem.id);
    final isDownloading = downloadState.activeDownloads.containsKey(mediaItem.id);
    final downloadProgress = downloadState.progressMap[mediaItem.id] ?? 0.0;

    ref.listen<AsyncValue<MediaItem?>>(currentMediaItemProvider, (prev, next) {
      final item = next.valueOrNull;
      if (item != null && item != prev?.valueOrNull) {
        _updateBgColor();
        _fetchArtist();
        setState(() => _lyrics = null);
        _fetchLyrics(item);
      }
    });

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 40),
            _buildHeader(mediaItem, isLiked, storage),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    _buildAlbumArt(player, mediaItem),
                    const SizedBox(height: 20),
                    _buildTitleAndLike(mediaItem, storage),
                    _streamProgressBar(player, mediaItem),
                    _playBackControl(player),
                    const SizedBox(height: 8),
                    _buildActionButtons(mediaItem, isDownloading, downloadProgress),
                    const SizedBox(height: 8),
                    _buildArtistCard(mediaItem),
                    const SizedBox(height: 24),
                    if (_hasUsableLyrics || _isLoadingLyrics)
                      _buildLyricsCard(player, mediaItem),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(MediaItem mediaItem, bool isLiked, StorageService storage) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
            onPressed: () => Navigator.of(context).pop(),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.55,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "NOW PLAYING",
                  style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 2),
                _marqueeText(
                  mediaItem.album ?? '',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
            onPressed: () {
              final result = _buildMuzoItemFromMedia(mediaItem);
              SongOptionsMenu.show(ref, result, fromPlayer: true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(AudioPlayer player, MediaItem mediaItem) {
    return SizedBox(
      height: 340,
      child: StreamBuilder<SequenceState?>(
        stream: player.sequenceStateStream,
        builder: (context, seqSnap) {
          final seq = seqSnap.data;
          final queue = seq?.sequence ?? [];
          final curIdx = seq?.currentIndex ?? 0;

          if (queue.isEmpty) {
            return Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: mediaItem.artUri?.toString() ?? '',
                  width: MediaQuery.of(context).size.width * 0.80,
                  height: MediaQuery.of(context).size.width * 0.80,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: MediaQuery.of(context).size.width * 0.80,
                    height: MediaQuery.of(context).size.width * 0.80,
                    color: Colors.grey[800],
                    child: const Icon(Icons.music_note, color: Colors.white38, size: 64),
                  ),
                ),
              ),
            );
          }

          return PageView.builder(
            controller: _pageController,
            itemCount: queue.length,
            onPageChanged: (index) async {
              if (index != curIdx) {
                await player.seek(Duration.zero, index: index);
                await player.play();
              }
            },
            itemBuilder: (context, index) {
              final item = queue[index].tag as MediaItem;
              final screenWidth = MediaQuery.of(context).size.width;
              double imageWidth = screenWidth * 0.80 > 400 ? 400 : screenWidth * 0.80;
              return Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: item.artUri?.toString() ?? '',
                    width: imageWidth,
                    height: imageWidth,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: imageWidth,
                      height: imageWidth,
                      color: Colors.grey[800],
                      child: const Icon(Icons.music_note, color: Colors.white38, size: 64),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTitleAndLike(MediaItem mediaItem, StorageService storage) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _marqueeText(
                    mediaItem.title,
                    fontSize: 22,
                    letterSpacing: -1.4,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: 4),
                  _marqueeText(
                    mediaItem.artist ?? 'Unknown Artist',
                    fontSize: 15,
                    letterSpacing: -1.4,
                    fontWeight: FontWeight.w300,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              HapticFeedback.lightImpact();
              final result = _buildMuzoItemFromMedia(mediaItem);
              storage.toggleFavorite(result);
            },
            child: ValueListenableBuilder<List<MuzoItem>>(
              valueListenable: storage.favoritesListenable,
              builder: (context, favorites, _) {
                final liked = storage.isFavorite(mediaItem.id);
                return Image.asset(
                  liked ? 'assets/icons/tick.png' : 'assets/icons/add.png',
                  width: 32,
                  height: 32,
                  color: liked
                      ? const Color(0xFF1DDA63)
                      : Colors.white70,
                );
              },
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _streamProgressBar(AudioPlayer player, MediaItem mediaItem) {
    final total = mediaItem.duration ?? player.duration ?? Duration.zero;

    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, posSnapshot) {
        final pos = posSnapshot.data ?? Duration.zero;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 5),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5, pressedElevation: 5, elevation: 0.5),
                  overlayShape: SliderComponentShape.noOverlay,
                  trackShape: const _CustomTrackShape(activeTrackHeight: 2, inactiveTrackHeight: 2),
                  trackHeight: 2,
                ),
                child: Slider(
                  value: total.inMilliseconds > 0
                      ? (pos.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
                      : 0.0,
                  onChanged: total == Duration.zero
                      ? null
                      : (v) => player.seek(Duration(milliseconds: (v * total.inMilliseconds).toInt())),
                  activeColor: Colors.white,
                  inactiveColor: Colors.white54.withAlpha(50),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(pos), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(_fmt(total), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _playBackControl(AudioPlayer player) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          StreamBuilder<bool>(
            stream: player.shuffleModeEnabledStream,
            builder: (context, snap) {
              final isShuffle = snap.data ?? false;
              return GestureDetector(
                onTap: () => player.setShuffleModeEnabled(!isShuffle),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Icon(Icons.shuffle, color: isShuffle ? const Color(0xFF1DB954) : Colors.white70, size: 24),
                      ),
                      if (isShuffle)
                        Positioned(
                          bottom: 2,
                          child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF1DB954), shape: BoxShape.circle)),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          GestureDetector(
            onTap: () => player.seekToPrevious(),
            child: const SizedBox(
              width: 55,
              height: 55,
              child: Center(child: Icon(Icons.skip_previous, color: Colors.white, size: 33)),
            ),
          ),
          StreamBuilder<PlayerState>(
            stream: player.playerStateStream,
            builder: (context, snapshot) {
              final state = snapshot.data;
              final playing = state?.playing ?? false;
              final isLoading = state?.processingState == ProcessingState.loading ||
                  state?.processingState == ProcessingState.buffering;

              return GestureDetector(
                onTap: () {
                  if (isLoading) return;
                  playing ? player.pause() : player.play();
                },
                child: SizedBox(
                  width: 75,
                  height: 75,
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 64,
                            height: 64,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF1DB954)),
                          )
                        : Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: Icon(
                              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.black,
                              size: 38,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
          GestureDetector(
            onTap: () => player.seekToNext(),
            child: const SizedBox(
              width: 55,
              height: 55,
              child: Center(child: Icon(Icons.skip_next, color: Colors.white, size: 33)),
            ),
          ),
          StreamBuilder<LoopMode>(
            stream: player.loopModeStream,
            builder: (context, snap) {
              final repeatMode = snap.data ?? LoopMode.off;
              return GestureDetector(
                onTap: () async {
                  if (repeatMode == LoopMode.off) {
                    await player.setLoopMode(LoopMode.all);
                  } else if (repeatMode == LoopMode.all) {
                    await player.setLoopMode(LoopMode.one);
                  } else {
                    await player.setLoopMode(LoopMode.off);
                  }
                },
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Icon(
                          repeatMode == LoopMode.one ? Icons.repeat_one : Icons.repeat,
                          color: repeatMode != LoopMode.off ? const Color(0xFF1DB954) : Colors.white70,
                          size: 24,
                        ),
                      ),
                      if (repeatMode != LoopMode.off)
                        Positioned(
                          bottom: 2,
                          child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF1DB954), shape: BoxShape.circle)),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(MediaItem mediaItem, bool isDownloading, double downloadProgress) {
    final storage = ref.read(storageServiceProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Download
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: isDownloading
                ? null
                : () async {
                    if (storage.isDownloaded(mediaItem.id)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Already downloaded"), duration: Duration(seconds: 1)),
                      );
                      return;
                    }
                    HapticFeedback.lightImpact();
                    final result = _buildMuzoItemFromMedia(mediaItem);
                    await ref.read(downloadProvider.notifier).startDownload(result);
                  },
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: isDownloading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          value: downloadProgress,
                          strokeWidth: 2,
                          color: const Color(0xFF1DDA63),
                          backgroundColor: Colors.white24,
                        ),
                      )
                    : ValueListenableBuilder(
                        valueListenable: storage.downloadsListenable,
                        builder: (context, _, __) {
                          final done = storage.isDownloaded(mediaItem.id);
                          return Image.asset(
                            done
                                ? 'assets/icons/complete_download.png'
                                : 'assets/icons/download.png',
                            width: 32,
                            height: 32,
                            color: done
                                ? const Color(0xFF1DDA63)
                                : Colors.white70,
                          );
                        },
                      ),
              ),
            ),
          ),
          // Sleep Timer
          Consumer(
            builder: (context, ref, _) {
              final remaining = ref.watch(sleepTimerProvider);
              final hasTimer = remaining != null && remaining > Duration.zero;
              return GestureDetector(
                onTap: () => _showSleepTimerDialog(),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: Icon(
                      Icons.timer_outlined,
                      color: hasTimer ? const Color(0xFF1DB954) : Colors.white70,
                      size: 24,
                    ),
                  ),
                ),
              );
            },
          ),
          const Spacer(),
          // Share
          GestureDetector(
            onTap: () async {
              final details = StringBuffer();
              details.writeln("Song: ${mediaItem.title}");
              if (mediaItem.artist != null) details.writeln("Artist: ${mediaItem.artist}");
              if (mediaItem.album != null) details.writeln("Album: ${mediaItem.album}");
              await Share.share(details.toString(), subject: "Sharing from Tunefy");
            },
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Center(child: Icon(Icons.share_outlined, color: Colors.white70, size: 24)),
            ),
          ),
          // Queue
          GestureDetector(
            onTap: _openQueueSheet,
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Center(child: Icon(Icons.queue_music, color: Colors.white70, size: 24)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistCard(MediaItem mediaItem) {
    final artistName = mediaItem.artist ?? '';
    final avatarUrl = mediaItem.artUri?.toString() ?? '';
    final displayName = (_artistDetails?.artistName.isNotEmpty ?? false)
        ? _artistDetails!.artistName
        : artistName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.cardTranslucent,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 190,
                    child: avatarUrl.isNotEmpty
                        ? Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[800],
                              child: const Icon(Icons.person, color: Colors.white38, size: 48),
                            ),
                          )
                        : Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.person, color: Colors.white38, size: 48),
                          ),
                  ),
                  Container(
                    height: 190,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withAlpha(150),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 14,
                    left: 16,
                    right: 16,
                    child: Text(
                      'About the artist',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    letterSpacing: -0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                child: _buildArtistBio(displayName),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtistBio(String artistName) {
    if (artistName.trim().isEmpty) {
      return Text(
        'Tap to open the artist page',
        style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
      );
    }

    final bio = ref.watch(artistBioProvider(artistName)).valueOrNull;

    if (bio == null || bio.isEmpty) {
      return Text(
        'Tap to open the artist page',
        style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
      );
    }

    const maxLines = 2;
    final isLong = bio.length > 160;
    final needsEllipsis = isLong && !_biographyExpanded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          needsEllipsis ? bio : bio,
          maxLines: needsEllipsis ? maxLines : null,
          overflow: needsEllipsis ? TextOverflow.ellipsis : null,
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
        if (isLong)
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => setState(() => _biographyExpanded = !_biographyExpanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _biographyExpanded ? 'Réduire' : 'Lire le tout',
                    style: const TextStyle(
                      color: Color(0xFF1DDA63),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _biographyExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF1DDA63),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLyricsCard(AudioPlayer player, MediaItem mediaItem) {
    final playerColour = ref.watch(playerColourProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: playerColour,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text(
                        'Lyric preview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.music_note,
                        color: const Color(0xFF1DDA63),
                        size: 16,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 400,
                  width: double.infinity,
                  child: _buildLyricsBody(player, mediaItem),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height: 34,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LyricsFullScreen(mediaItem: mediaItem),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text(
                          'Voir les paroles',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLyricsBody(AudioPlayer player, MediaItem mediaItem) {
    if (_lyrics == null) {
      return _isLoadingLyrics
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1DDA63),
                strokeWidth: 2,
              ),
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lyrics_outlined, color: Colors.white38, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'No lyrics found',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            );
    }

    final timed = _parseSyncedLines(_lyrics!);

    if (timed.isEmpty) {
      final plain = _lyrics!.plainLyrics.trim();
      final lines = plain
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      if (lines.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lyrics_outlined, color: Colors.white38, size: 32),
              SizedBox(height: 8),
              Text(
                'No lyrics found',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        );
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                line,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ),
        ],
      );
    }

    if (timed.length != _lyricsLineKeys.length) {
      _lyricsLineKeys
        ..clear()
        ..addAll(List.generate(timed.length, (_) => GlobalKey()));
    }

    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snap) {
        final position = snap.data ?? Duration.zero;
        int active = 0;
        for (var i = 0; i < timed.length; i++) {
          if (position >= timed[i].time) {
            active = i;
          } else {
            break;
          }
        }

        if (active != _lyricsActiveLine) {
          _lyricsActiveLine = active;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || active >= _lyricsLineKeys.length) return;
            final ctx = _lyricsLineKeys[active].currentContext;
            if (ctx != null) {
              Scrollable.ensureVisible(
                ctx,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                alignment: 0.3,
              );
            }
          });
        }

        return ListView.builder(
          controller: _lyricsScrollController,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          itemCount: timed.length,
          itemBuilder: (context, i) {
            final line = timed[i];
            final isActive = i == active;
            return Padding(
              key: _lyricsLineKeys[i],
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white54,
                  fontSize: isActive ? 16.5 : 14.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  height: 1.5,
                ),
                child: Text(
                  line.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<_TimedLyricLine> _parseSyncedLines(Lyrics lyrics) {
    final synced = lyrics.syncedLyrics.trim();
    if (synced.isNotEmpty) {
      final reg = RegExp(r'\[(\d+):(\d+)[.:](\d+)\]\s*(.*)');
      final parsed = <_TimedLyricLine>[];
      for (final raw in synced.split('\n')) {
        final m = reg.firstMatch(raw);
        if (m == null) continue;
        final min = int.tryParse(m.group(1)!) ?? 0;
        final sec = int.tryParse(m.group(2)!) ?? 0;
        final hundredths = int.tryParse(m.group(3)!) ?? 0;
        parsed.add(_TimedLyricLine(
          time: Duration(minutes: min, seconds: sec, milliseconds: hundredths * 10),
          text: (m.group(4) ?? '').trim(),
        ));
      }
      if (parsed.isNotEmpty) return parsed;
    }

    return const <_TimedLyricLine>[];
  }

  void _showSleepTimerDialog() {
    showDialog(
      context: context,
      builder: (_) => const SleepTimerDialog(),
    );
  }
}

class _TimedLyricLine {
  const _TimedLyricLine({required this.time, required this.text});

  final Duration time;
  final String text;
}

class _CustomTrackShape extends SliderTrackShape {
  final double activeTrackHeight;
  final double inactiveTrackHeight;

  const _CustomTrackShape({required this.activeTrackHeight, required this.inactiveTrackHeight});

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = inactiveTrackHeight;
    final double trackLeft = offset.dx + sliderTheme.overlayShape!.getPreferredSize(isEnabled, isDiscrete).width / 2;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width - sliderTheme.overlayShape!.getPreferredSize(isEnabled, isDiscrete).width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
    Offset? secondaryOffset,
  }) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final Paint activePaint = Paint()..color = sliderTheme.activeTrackColor ?? Colors.white;
    final Paint inactivePaint = Paint()..color = sliderTheme.inactiveTrackColor ?? Colors.grey;
    final Rect leftTrackSegment = Rect.fromLTRB(
      trackRect.left,
      trackRect.top + (trackRect.height - activeTrackHeight) / 2,
      thumbCenter.dx,
      trackRect.bottom - (trackRect.height - activeTrackHeight) / 2,
    );
    final Rect rightTrackSegment = Rect.fromLTRB(
      thumbCenter.dx,
      trackRect.top + (trackRect.height - inactiveTrackHeight) / 2,
      trackRect.right,
      trackRect.bottom - (trackRect.height - inactiveTrackHeight) / 2,
    );
    context.canvas.drawRect(leftTrackSegment, activePaint);
    context.canvas.drawRect(rightTrackSegment, inactivePaint);
  }
}
