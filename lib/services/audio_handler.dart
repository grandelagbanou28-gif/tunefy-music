import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:tunefy/models/track.dart';
import 'package:tunefy/services/stream_extraction_service.dart';

class TunefyAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);
  final ValueNotifier<bool> isLoadingStream = ValueNotifier(false);
  final ValueNotifier<String?> currentStreamUrl = ValueNotifier(null);

  Duration _lastPosition = Duration.zero;
  bool _wasPlaying = false;
  bool _recovering = false;

  AudioPlayer get player => _player;
  ConcatenatingAudioSource get playlist => _playlist;

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<int?>? _currentIndexSubscription;
  StreamSubscription<ProcessingState>? _processingSub;

  TunefyAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ));
    } catch (e) {
      debugPrint("AudioSession config error: $e");
    }

    _playerStateSubscription = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering) {
        isLoadingStream.value = true;
      } else {
        isLoadingStream.value = false;
      }
    });

    _processingSub = _player.processingStateStream.listen((processing) {
      if (processing == ProcessingState.ready || processing == ProcessingState.buffering) {
        _lastPosition = _player.position;
        _wasPlaying = _player.playing;
      }
      if (processing == ProcessingState.idle && _wasPlaying && !_recovering) {
        debugPrint('AudioHandler: Unexpected idle, recovering from $_lastPosition');
        _recoverPosition();
      }
    });

    _currentIndexSubscription = _player.currentIndexStream.listen((index) {
      if (index == null) return;
      final sequence = _player.sequenceState?.sequence;
      if (sequence == null || index >= sequence.length) return;
      for (int i = 0; i <= 3; i++) {
        if (index + i < sequence.length) {
          final source = sequence[index + i];
          if (source is ResolvingAudioSource) {
            source.resolve();
          }
        }
      }
    });
  }

  Future<void> _recoverPosition() async {
    if (_recovering) return;
    _recovering = true;
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_player.processingState == ProcessingState.idle && _wasPlaying) {
        final sequence = _player.sequenceState?.sequence;
        final index = _player.currentIndex;
        if (sequence != null && index != null && index < sequence.length) {
          final source = sequence[index];
          if (source is ResolvingAudioSource) {
            source.invalidateUrl();
            await source.resolve();
          }
          await _player.seek(_lastPosition, index: index);
          await _player.play();
          debugPrint('AudioHandler: Recovered to $_lastPosition');
        }
      }
    } catch (e) {
      debugPrint('AudioHandler: Recovery failed: $e');
    } finally {
      _recovering = false;
    }
  }

  Future<void> playTrack(Track track) async {
    try {
      isLoadingStream.value = true;

      final source = _createLazyAudioSource(track);
      if (source == null) {
        isLoadingStream.value = false;
        debugPrint('playTrack: Failed to create audio source');
        return;
      }

      await _playlist.clear();
      await _playlist.add(source);
      await _player.setAudioSource(_playlist, initialPosition: Duration.zero, initialIndex: 0, preload: true);
      unawaited(_player.play());

      isLoadingStream.value = false;
    } catch (e) {
      debugPrint('Error playing track: $e');
      isLoadingStream.value = false;
    }
  }



  Future<void> playAll(List<Track> tracks, {Track? startAt}) async {
    try {
      if (tracks.isEmpty) return;
      await _playlist.clear();

      int startIndex = 0;
      if (startAt != null) {
        startIndex = tracks.indexWhere((t) => t.videoId == startAt.videoId && t.title == startAt.title);
        if (startIndex < 0) startIndex = 0;
      }

      final allSources = tracks.map((t) => _createLazyAudioSource(t)).whereType<AudioSource>().toList();
      if (allSources.isNotEmpty) {
        await _playlist.addAll(allSources);
        await _player.setAudioSource(_playlist, initialPosition: Duration.zero, initialIndex: startIndex, preload: true);
        unawaited(_player.play());
      }
    } catch (e) {
      debugPrint('Error playing all: $e');
    }
  }

  Future<void> addToQueue(Track track) async {
    try {
      final source = await _createAudioSource(track);
      if (source != null) {
        await _playlist.add(source);
        if (_player.audioSource != _playlist) {
          await _player.setAudioSource(_playlist);
        }
      }
    } catch (e) {
      debugPrint('Error adding to queue: $e');
    }
  }

  Future<void> playNext(Track track) async {
    try {
      final index = _player.currentIndex ?? 0;
      final source = await _createAudioSource(track);
      if (source != null) {
        await _playlist.insert(index + 1, source);
      }
    } catch (e) {
      debugPrint('Error playing next: $e');
    }
  }

  Future<AudioSource?> _createAudioSource(Track track) async {
    try {
      if (track.videoId == null && track.audioUrl == null) return null;

      Uri audioUri;
      if (track.audioUrl != null) {
        audioUri = Uri.parse(track.audioUrl!);
      } else {
        final streamUrl = await StreamExtractionService.getStreamUrl(
          track.videoId!,
          title: track.title,
          artist: track.artist,
          durationSeconds: track.duration?.inSeconds,
        );
        if (streamUrl == null) return null;
        audioUri = Uri.parse(streamUrl);
        currentStreamUrl.value = streamUrl;
        StreamExtractionService.currentStreamUrl.value = streamUrl;
      }

      return AudioSource.uri(
        audioUri,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36',
        },
        tag: MediaItem(
          id: track.videoId ?? track.title,
          album: "Tunefy",
          title: track.title,
          artist: track.artist,
          duration: track.duration,
          artUri: track.albumImage != null ? Uri.parse(track.albumImage!) : null,
        ),
      );
    } catch (e) {
      debugPrint('Error creating audio source: $e');
      return null;
    }
  }

  AudioSource? _createLazyAudioSource(Track track) {
    if (track.videoId == null && track.audioUrl == null) return null;
    final mediaItem = MediaItem(
      id: track.videoId ?? track.title,
      album: 'Tunefy',
      title: track.title,
      artist: track.artist,
      duration: track.duration,
      artUri: track.albumImage != null ? Uri.parse(track.albumImage!) : null,
    );
    return ResolvingAudioSource(
      videoId: track.videoId ?? '',
      tag: mediaItem,
      track: track,
    );
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();
  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> skipToNext() async { await _player.seekToNext(); unawaited(_player.play()); }
  Future<void> skipToPrevious() async { await _player.seekToPrevious(); unawaited(_player.play()); }

  Future<void> removeQueueItem(int index) async {
    try { await _playlist.removeAt(index); } catch (e) {}
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    try {
      if (oldIndex < newIndex) newIndex -= 1;
      await _playlist.move(oldIndex, newIndex);
    } catch (e) {}
  }

  void dispose() {
    _playerStateSubscription?.cancel();
    _currentIndexSubscription?.cancel();
    _processingSub?.cancel();
    isLoadingStream.dispose();
    _player.dispose();
  }
}

class ResolvingAudioSource extends StreamAudioSource {
  final String videoId;
  String? _resolvedUrl;
  Future<void>? _resolveFuture;
  final Track? track;

  ResolvingAudioSource({required this.videoId, this.track, super.tag});

  void invalidateUrl() {
    _resolvedUrl = null;
  }

  Future<void> resolve() async {
    if (_resolvedUrl != null) return;
    if (_resolveFuture != null) { await _resolveFuture; return; }
    final mediaItem = tag as MediaItem?;
    final future = StreamExtractionService.getStreamUrl(
      videoId,
      title: mediaItem?.title,
      artist: mediaItem?.artist,
      durationSeconds: mediaItem?.duration?.inSeconds,
    ).then((url) {
      _resolvedUrl = url;
      if (url != null) {
        StreamExtractionService.currentStreamUrl.value = url;
      }
    }).catchError((e) {
      debugPrint('Error pre-resolving $videoId: $e');
    }).whenComplete(() { _resolveFuture = null; });
    _resolveFuture = future;
    await future;
  }

  Future<StreamAudioResponse> _fetchAudio(int? start, int? end) async {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(_resolvedUrl!));
    request.headers.add('User-Agent', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N)');
    if (start != null || end != null) {
      request.headers.add('Range', 'bytes=${start ?? 0}-${end != null ? (end - 1) : ""}');
    }
    final response = await request.close();
    final contentLength = response.contentLength;
    int sourceLength = contentLength;
    final contentRange = response.headers.value('content-range');
    if (contentRange != null) {
      final parts = contentRange.split('/');
      if (parts.length == 2) sourceLength = int.tryParse(parts[1]) ?? contentLength;
    }
    return StreamAudioResponse(
      sourceLength: sourceLength,
      contentLength: contentLength,
      offset: start ?? 0,
      contentType: response.headers.contentType?.toString() ?? 'audio/mpeg',
      stream: response,
    );
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    if (_resolvedUrl == null) {
      await resolve();
      if (_resolvedUrl == null) throw Exception('Failed to resolve stream URL for $videoId');
    }
    try {
      return await _fetchAudio(start, end);
    } catch (e) {
      debugPrint('ResolvingAudioSource: Request failed for $videoId, re-resolving: $e');
      invalidateUrl();
      await resolve();
      if (_resolvedUrl == null) throw Exception('Failed to re-resolve stream URL for $videoId');
      return await _fetchAudio(start, end);
    }
  }
}
