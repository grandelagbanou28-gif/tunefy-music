import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tunefy/services/audio_handler.dart';
import 'package:tunefy/services/lyrics_service.dart';
import 'package:tunefy/services/premium_service.dart';
import 'package:tunefy/services/stream_extraction_service.dart';
import 'package:tunefy/models/track.dart';
import 'package:tunefy/helpers/tunefy_helpers.dart';

/// Signal global pour afficher le modal Premium
final showPremiumPrompt = ValueNotifier<String?>(null);

class PlayerProvider extends ChangeNotifier {
  final TunefyAudioHandler _audioHandler = TunefyAudioHandler();
  final LyricsService _lyricsService = LyricsService();

  TunefyAudioHandler get audioHandler => _audioHandler;
  AudioPlayer get player => _audioHandler.player;

  Track? _currentTrack;
  Track? get currentTrack => _currentTrack;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Duration _position = Duration.zero;
  Duration get position => _position;

  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  Lyrics? _currentLyrics;
  Lyrics? get currentLyrics => _currentLyrics;

  bool _isLoadingLyrics = false;
  bool get isLoadingLyrics => _isLoadingLyrics;

  bool _isLoadingStream = false;
  bool get isLoadingStream => _isLoadingStream;

  String? _currentStreamUrl;
  String? get currentStreamUrl => _currentStreamUrl;

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<int?>? _currentIndexSub;
  VoidCallback? _loadingListener;

  PlayerProvider() {
    _playerStateSub = player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      globalIsPlaying.value = state.playing;
      notifyListeners();
    });

    _positionSub = player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _durationSub = player.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });

    _loadingListener = () {
      _isLoadingStream = _audioHandler.isLoadingStream.value;
      _currentStreamUrl = StreamExtractionService.currentStreamUrl.value
          ?? _audioHandler.currentStreamUrl.value;
      notifyListeners();
    };
    _audioHandler.isLoadingStream.addListener(_loadingListener!);
    _audioHandler.currentStreamUrl.addListener(_loadingListener!);
    StreamExtractionService.currentStreamUrl.addListener(_loadingListener!);

    _currentIndexSub = player.currentIndexStream.listen((_) {
      _updateCurrentTrackFromPlayer();
    });
  }

  Future<void> playTrack(Track track, [List<Track>? playlist]) async {
    _currentTrack = track;
    _currentLyrics = null;
    notifyListeners();

    if (playlist != null && playlist.isNotEmpty) {
      await _audioHandler.playAll(playlist, startAt: track);
    } else {
      await _audioHandler.playTrack(track);
    }
    _fetchLyrics(track);
  }

  Future<void> playAll(List<Track> tracks) async {
    if (tracks.isNotEmpty) {
      _currentTrack = tracks.first;
      _currentLyrics = null;
      notifyListeners();
      _fetchLyrics(tracks.first);
    }
    await _audioHandler.playAll(tracks);
  }

  Future<void> addToQueue(Track track) async {
    await _audioHandler.addToQueue(track);
  }

  Future<void> playNext(Track track) async {
    await _audioHandler.playNext(track);
  }

  Future<void> pause() async {
    await _audioHandler.pause();
  }

  Future<void> resume() async {
    await _audioHandler.resume();
  }

  Future<void> togglePlay() async {
    if (player.playing) {
      await pause();
    } else if (player.processingState == ProcessingState.idle ||
               player.processingState == ProcessingState.completed) {
      final seq = player.sequenceState?.sequence;
      if (_currentTrack != null && seq != null && seq.isNotEmpty) {
        final idx = player.currentIndex ?? 0;
        await player.seek(_position, index: idx);
        await resume();
      }
    } else {
      await resume();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioHandler.seek(position);
  }

  Future<void> skipToNext() async {
    if (!PremiumService.isPremium) {
      final box = Hive.box('settings');
      final List<dynamic> raw = box.get('skipTimestamps', defaultValue: []) as List<dynamic>;
      final now = DateTime.now().millisecondsSinceEpoch;
      // Garder seulement les skips de la dernière heure
      final recent = raw.where((t) => now - (t as int) < 3600000).toList();
      if (recent.length >= 6) {
        showPremiumPrompt.value = 'limite de skips atteinte';
        return;
      }
      recent.add(now);
      await box.put('skipTimestamps', recent);
    }
    await _audioHandler.skipToNext();
    _updateCurrentTrackFromPlayer();
  }

  Future<void> skipToPrevious() async {
    await _audioHandler.skipToPrevious();
    _updateCurrentTrackFromPlayer();
  }

  void _updateCurrentTrackFromPlayer() {
    final state = player.sequenceState;
    if (state != null && state.currentSource != null) {
      final tag = state.currentSource!.tag;
      if (tag is MediaItem) {
        _currentTrack = Track(
          videoId: tag.id,
          title: tag.title,
          artist: tag.artist ?? '',
          albumImage: tag.artUri?.toString(),
          duration: tag.duration,
        );
        _currentLyrics = null;
        notifyListeners();
        _fetchLyrics(_currentTrack!);
      }
    }
  }

  Future<void> _fetchLyrics(Track track) async {
    _isLoadingLyrics = true;
    notifyListeners();
    try {
      _currentLyrics = await _lyricsService.fetchLyrics(
        track.title,
        track.artist,
        track.duration?.inSeconds ?? 0,
      );
    } catch (e) {
      debugPrint('Error fetching lyrics: $e');
    }
    _isLoadingLyrics = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _currentIndexSub?.cancel();
    if (_loadingListener != null) {
      _audioHandler.isLoadingStream.removeListener(_loadingListener!);
      _audioHandler.currentStreamUrl.removeListener(_loadingListener!);
      StreamExtractionService.currentStreamUrl.removeListener(_loadingListener!);
    }
    _audioHandler.dispose();
    super.dispose();
  }
}
