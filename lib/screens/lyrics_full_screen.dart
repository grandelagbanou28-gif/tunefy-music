import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/providers/player_provider.dart';
import 'package:muzo/services/lyrics_service.dart';
import 'package:muzo/services/storage_service.dart';
import 'package:muzo/widgets/song_options_menu.dart';

/// A single timed lyric line parsed from syncedLyrics ([mm:ss.xx] text).
class _TimedLine {
  final Duration time;
  final String text;
  const _TimedLine(this.time, this.text);
}

class LyricsFullScreen extends ConsumerStatefulWidget {
  final MediaItem mediaItem;

  const LyricsFullScreen({super.key, required this.mediaItem});

  @override
  ConsumerState<LyricsFullScreen> createState() => _LyricsFullScreenState();
}

class _LyricsFullScreenState extends ConsumerState<LyricsFullScreen> {
  Lyrics? _lyrics;
  bool _isLoadingLyrics = false;
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _lineKeys = [];
  int _activeLine = -1;

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchLyrics() async {
    if (_isLoadingLyrics) return;
    _isLoadingLyrics = true;
    try {
      final service = ref.read(lyricsServiceProvider);
      final lyrics = await service.fetchLyrics(
        widget.mediaItem.title,
        widget.mediaItem.artist ?? '',
        widget.mediaItem.duration?.inSeconds ?? 0,
      );
      if (mounted) {
        setState(() {
          _lyrics = lyrics;
          final timed = _parseSynced(lyrics);
          _lineKeys.clear();
          _lineKeys.addAll(List.generate(timed.length, (_) => GlobalKey()));
        });
      }
    } catch (_) {
      if (mounted) setState(() => _lyrics = null);
    }
    _isLoadingLyrics = false;
  }

  /// Parse [mm:ss.xx] lines from syncedLyrics when available. Falls back to
  /// plain lines (never null).
  List<_TimedLine> _parseSynced(Lyrics? lyrics) {
    if (lyrics == null) return const [];

    final synced = lyrics.syncedLyrics.trim();
    if (synced.isNotEmpty) {
      final re = RegExp(r'\[(\d+):(\d+)[.:](\d+)\]\s*(.*)');
      final parsed = <_TimedLine>[];
      for (final line in synced.split('\n')) {
        final m = re.firstMatch(line);
        if (m == null) continue;
        final minutes = int.parse(m.group(1)!);
        final seconds = int.parse(m.group(2)!);
        final frac = m.group(3)!;
        final ms = minutes * 60000 +
            seconds * 1000 +
            int.parse(frac.padRight(2, '0').substring(0, 2)) * 10;
        final text = m.group(4)?.trim() ?? '';
        if (text.isNotEmpty) parsed.add(_TimedLine(Duration(milliseconds: ms), text));
      }
      if (parsed.isNotEmpty) return parsed;
    }

    return lyrics.plainLyrics
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .map((l) => _TimedLine(Duration.zero, l))
        .toList();
  }

  void _scrollToActive(int index) {
    if (index < 0 || index >= _lineKeys.length) return;
    final context = _lineKeys[index].currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      alignment: 0.25,
    );
  }

  MuzoItem _muzoItem(MediaItem mediaItem) {
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

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final mediaItem = widget.mediaItem;
    final audioHandler = ref.watch(audioHandlerProvider);
    final player = audioHandler.player;
    final storage = ref.read(storageServiceProvider);
    final bgUrl = mediaItem.artUri?.toString() ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: bgUrl.isNotEmpty
                ? Image.network(
                    bgUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[900],
                      child: const Icon(Icons.music_note, color: Colors.white12, size: 90),
                    ),
                  )
                : Container(
                    color: Colors.grey[900],
                    child: const Icon(Icons.music_note, color: Colors.white12, size: 90),
                  ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(210),
                    Colors.black.withAlpha(170),
                    Colors.black.withAlpha(235),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(mediaItem, storage),
                _buildSquareArt(mediaItem),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: _buildLyricsBody(player),
                  ),
                ),
                _buildProgressBar(player, mediaItem),
                _buildNavControls(player),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareArt(MediaItem mediaItem) {
    final url = mediaItem.artUri?.toString() ?? '';
    final artist = mediaItem.artist ?? 'Unknown Artist';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: url.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.music_note, color: Colors.white38, size: 24),
                      ),
                    ),
                  )
                : Container(
                    color: Colors.grey[800],
                    child: const Icon(Icons.music_note, color: Colors.white38, size: 24),
                  ),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(MediaItem mediaItem, StorageService storage) {
    final result = _muzoItem(mediaItem);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.navigate_before, size: 30, color: Colors.white),
            tooltip: 'Retour',
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 18),
                const Text(
                  'PAROLES',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<List<MuzoItem>>(
            valueListenable: storage.favoritesListenable,
            builder: (context, _, __) {
              final liked = storage.isFavorite(mediaItem.id);
              return IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  storage.toggleFavorite(result);
                },
                icon: Icon(
                  liked ? Icons.star_rounded : Icons.star_border_rounded,
                  color: liked ? const Color(0xFF1DDA63) : Colors.white,
                  size: 26,
                ),
              );
            },
          ),
          IconButton(
            onPressed: () => SongOptionsMenu.show(ref, result, fromPlayer: true),
            icon: const Icon(Icons.more_horiz, color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsBody(AudioPlayer player) {
    if (_lyrics == null) {
      return _isLoadingLyrics
          ? const Padding(
              padding: EdgeInsets.only(top: 120),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF1DDA63), strokeWidth: 2),
              ),
            )
          : const Padding(
              padding: EdgeInsets.only(top: 160),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.lyrics_outlined, color: Colors.white38, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'Aucune parole trouvée',
                      style: TextStyle(color: Colors.white54, fontSize: 15),
                    ),
                  ],
                ),
              ),
            );
    }

    final timed = _parseSynced(_lyrics);
    if (timed.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 160),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.lyrics_outlined, color: Colors.white38, size: 48),
              SizedBox(height: 12),
              Text(
                'Aucune parole trouvée',
                style: TextStyle(color: Colors.white54, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    final hasSync = _lyrics!.syncedLyrics.trim().isNotEmpty;

    if (!hasSync) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in timed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                line.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ),
        ],
      );
    }

    // Synchronized view with auto-scroll to the active line.
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snap) {
        final pos = snap.data ?? Duration.zero;
        int active = 0;
        for (var i = 0; i < timed.length; i++) {
          if (pos >= timed[i].time) {
            active = i;
          } else {
            break;
          }
        }
        if (active != _activeLine) {
          _activeLine = active;
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive(active));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < timed.length; i++)
              Padding(
                key: _lineKeys.length == timed.length ? _lineKeys[i] : null,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: TextStyle(
                    color: i == active ? Colors.white : Colors.white38,
                    fontSize: i == active ? 19 : 16,
                    fontWeight: i == active ? FontWeight.w700 : FontWeight.w400,
                    letterSpacing: -0.3,
                    height: 1.5,
                  ),
                  child: Text(timed[i].text),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildProgressBar(AudioPlayer player, MediaItem mediaItem) {
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
                  trackShape: const _LyricsTrackShape(activeTrackHeight: 2, inactiveTrackHeight: 2),
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
                padding: const EdgeInsets.symmetric(vertical: 6),
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

  Widget _buildNavControls(AudioPlayer player) {
    return StreamBuilder<SequenceState?>(
      stream: player.sequenceStateStream,
      builder: (context, seqSnap) {
        final seq = seqSnap.data;
        final hasPrev = seq != null && seq.currentIndex > 0;
        final hasNext = seq != null && seq.currentIndex < seq.sequence.length - 1;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Previous',
              onPressed: hasPrev ? player.seekToPrevious : null,
              icon: Icon(
                Icons.skip_previous,
                color: hasPrev ? Colors.white : Colors.white30,
                size: 32,
              ),
            ),
            const SizedBox(width: 10),
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
                    width: 72,
                    height: 72,
                    child: Center(
                      child: isLoading
                          ? const SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF1DB954)),
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: Icon(
                                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.black,
                                size: 36,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            IconButton(
              tooltip: 'Next',
              onPressed: hasNext ? player.seekToNext : null,
              icon: Icon(
                Icons.skip_next,
                color: hasNext ? Colors.white : Colors.white30,
                size: 32,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LyricsTrackShape extends SliderTrackShape {
  final double activeTrackHeight;
  final double inactiveTrackHeight;

  const _LyricsTrackShape({required this.activeTrackHeight, required this.inactiveTrackHeight});

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