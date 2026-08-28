import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:muzo/services/muzo_api_service.dart';
import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/services/navigator_key.dart';
import 'package:muzo/services/storage_service.dart';
import 'package:muzo/widgets/glass_snackbar.dart';
import 'package:muzo/services/stream_extraction_service.dart';

class AudioHandler {
  final AudioPlayer _player = AudioPlayer();
  final StorageService _storage;
  late final MuzoApiService _apiService = MuzoApiService(_storage);
  late final MuzoApiService _musicApiService = _apiService;

  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(
    children: [],
  );

  String? _lastHistoryId;
  bool _isInitialLoading = false;

  final ValueNotifier<bool> isLoadingStream = ValueNotifier(false);

  /// True while the current playback was started from the clips feed — the
  /// main layout hides the mini player pill in that mode (background audio
  /// only, controlled from the notification).
  final ValueNotifier<bool> isClipPlayback = ValueNotifier(false);

  AudioPlayer get player => _player;
  ConcatenatingAudioSource get playlist => _playlist;

  final ValueNotifier<bool> isLofiModeNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isShuffleModeNotifier = ValueNotifier(false);

  static const platform = MethodChannel('com.shashwat.muzo/audio_effects');

  double _userVolume = 1.0;
  
  // Stream subscriptions for proper cleanup
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<int?>? _androidAudioSessionIdSubscription;
  StreamSubscription<SequenceState?>? _sequenceStateSubscription;
  StreamSubscription<int?>? _currentIndexSubscription;
  
  double get userVolume => _userVolume;

  Future<void> setVolume(double volume) async {
    _userVolume = volume.clamp(0.0, 1.0);
    await _player.setVolume(_userVolume);
  }

  AudioHandler(this._storage) {
    _init();
  }

  Future<void> toggleLofiMode() async {
    isLofiModeNotifier.value = !isLofiModeNotifier.value;
    await updateLofiSettings();
  }

  Future<void> updateLofiSettings() async {
    final enable = isLofiModeNotifier.value;

    if (enable) {
      await _player.setSpeed(_storage.lofiSpeed);
      await _player.setPitch(_storage.lofiPitch);
    } else {
      await _player.setSpeed(1.0);
      await _player.setPitch(1.0);
    }

    if (!kIsWeb && Platform.isAndroid) {
      final sessionId = _player.androidAudioSessionId;
      if (sessionId != null) {
        await _applyReverb(sessionId, enable);
      }
    }
  }

  Future<void> _init() async {
    // Configure audio session for optimal music playback quality
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));
    } catch (e) {
      debugPrint("Error configuring AudioSession: $e");
    }

    _playerStateSubscription = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering) {
        isLoadingStream.value = true;
      } else if (state.processingState == ProcessingState.ready ||
          state.processingState == ProcessingState.completed ||
          state.processingState == ProcessingState.idle) {
        isLoadingStream.value = false;
      }

      // NOTE: no automatic suggestion fetching here. Playback must never
      // start anything the user did not explicitly choose — when the queue
      // ends, the player simply stops.

      if (state.playing && state.processingState == ProcessingState.ready) {
        final index = _player.currentIndex;
        final sequence = _player.sequenceState?.sequence;
        if (index != null && sequence != null && index < sequence.length) {
          final source = sequence[index];
          final tag = source.tag;
          if (tag is MediaItem && tag.id != _lastHistoryId) {
            _lastHistoryId = tag.id;
            final result = MuzoItem(
              videoId: tag.id,
              title: tag.title,
              artists: [MuzoArtist(name: tag.artist ?? '', id: '')],
              thumbnails: [
                MuzoThumbnail(
                  url: tag.artUri?.toString() ?? '',
                  width: 0,
                  height: 0,
                ),
              ],
              resultType: tag.extras?['resultType'] ?? 'song',
              durationSeconds: tag.duration?.inSeconds,
              isExplicit: false,
              audioUrl: tag.extras?['audioUrl'],
            );
            _storage.addToHistory(result);
          } else if (tag is MuzoItem && tag.videoId != _lastHistoryId) {
            _lastHistoryId = tag.videoId;
            _storage.addToHistory(tag);
          }
          // Record listening stats for Sound Capsule
          if (tag is MediaItem) {
            final result = MuzoItem(
              videoId: tag.id,
              title: tag.title,
              artists: [MuzoArtist(name: tag.artist ?? '', id: '')],
              album: tag.album != null
                  ? MuzoAlbum(name: tag.album!, id: '')
                  : null,
              thumbnails: [
                MuzoThumbnail(
                  url: tag.artUri?.toString() ?? '',
                  width: 0,
                  height: 0,
                ),
              ],
              resultType: tag.extras?['resultType'] ?? 'song',
              durationSeconds: tag.duration?.inSeconds,
              isExplicit: false,
              audioUrl: tag.extras?['audioUrl'],
            );
            _storage.stats.recordPlay(result);
          } else if (tag is MuzoItem) {
            _storage.stats.recordPlay(tag);
          }
        }

        if (_isInitialLoading) {
          _isInitialLoading = false;
        }

        if (sequence != null && index != null) {
          if (sequence.isNotEmpty && index < sequence.length - 1) {
            for (int i = 1; i <= 3; i++) {
              if (index + i < sequence.length) {
                final source = sequence[index + i];
                if (source is ResolvingAudioSource) {
                  source.resolve();
                }
              }
            }
          }
        }
      }
    });

    _androidAudioSessionIdSubscription = _player.androidAudioSessionIdStream.listen((sessionId) {
      if (sessionId != null && isLofiModeNotifier.value) {
        _applyReverb(sessionId, true);
      }
    });

    _sequenceStateSubscription = _player.sequenceStateStream.listen((state) {
      if (state == null) return;
      if (_isInitialLoading) return;
      final sequence = state.sequence;
      final index = state.currentIndex;

      for (int i = 1; i <= 3; i++) {
        if (index + i < sequence.length) {
          final source = sequence[index + i];
          if (source is ResolvingAudioSource) {
            source.resolve();
          }
        }
      }
    });

    _currentIndexSubscription = _player.currentIndexStream.listen((index) async {
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

  Future<void> _applyReverb(int sessionId, bool enable) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await platform.invokeMethod('enableReverb', {
        'sessionId': sessionId,
        'enable': enable,
      });
    } catch (e) {
      debugPrint("Error toggling reverb: $e");
    }
  }

  Future<void> playVideo(dynamic video, {bool isClip = false}) async {
    try {
      _isInitialLoading = true;
      isLoadingStream.value = true;
      isClipPlayback.value = isClip;

      String? videoId = video is MuzoItem ? video.videoId : null;
      if (videoId == null) {
        debugPrint('playVideo: missing videoId');
        final context = navigatorKey.currentContext;
        if (context != null) {
          showGlassSnackBar(context, 'Cannot play this item: Missing ID');
        }
        _isInitialLoading = false;
        isLoadingStream.value = false;
        isClipPlayback.value = false;
        return;
      }

      // Extract stream URL — UI already shows loading state
      final source = await _createAudioSource(video);
      if (source == null) {
        isLoadingStream.value = false;
        _isInitialLoading = false;
        isClipPlayback.value = false;
        final context = navigatorKey.currentContext;
        if (context != null) {
          showGlassSnackBar(context, 'Failed to extract audio stream');
        }
        return;
      }

      // Keep the existing queue alive so songs keep chaining: if the tapped
      // song is already queued, jump to it; otherwise slot it in right after
      // the current track instead of wiping everything (the old behaviour
      // replaced the queue with a single track and playback stopped at the
      // end of every song).
      final existingIndex = _player.sequenceState?.sequence
          .indexWhere((s) => s.tag is MediaItem && (s.tag as MediaItem).id == videoId);
      if (existingIndex != null && existingIndex >= 0) {
        if (_player.audioSource != _playlist) {
          await _player.setAudioSource(_playlist);
        }
        await _player.seek(Duration.zero, index: existingIndex);
        _safePlay();
        unawaited(_waitForReadyThenClearLoading());
        return;
      }

      final currentIndex = _player.currentIndex;
      if (_player.audioSource == _playlist &&
          currentIndex != null &&
          _playlist.length > 0) {
        await _playlist.insert(currentIndex + 1, source);
        await _player.seek(Duration.zero, index: currentIndex + 1);
        _safePlay();
      } else {
        await _playlist.clear();
        await _playlist.add(source);
        await _player.setAudioSource(
          _playlist,
          initialPosition: Duration.zero,
          initialIndex: 0,
          preload: true,
        );
        _safePlay();
      }

      // Keep the loading spinner up until the new track is actually
      // producing sound, instead of clearing it the moment play() returns.
      unawaited(_waitForReadyThenClearLoading());
    } catch (e) {
      debugPrint('Error playing video: $e');
      isLoadingStream.value = false;
      _isInitialLoading = false;
      isClipPlayback.value = false;
      final context = navigatorKey.currentContext;
      if (context != null) {
        showGlassSnackBar(context, 'Playback failed: $e');
      }
    }
  }

  /// Waits (bounded) for the player to reach [ProcessingState.ready], then
  /// clears the global loading flag so spinners reflect real buffering.
  Future<void> _waitForReadyThenClearLoading() async {
    try {
      await _player.processingStateStream
          .firstWhere((s) => s == ProcessingState.ready)
          .timeout(const Duration(seconds: 12));
    } catch (_) {
      // Timeout or stream closed — clear anyway so the UI never hangs.
    } finally {
      isLoadingStream.value = false;
      _isInitialLoading = false;
    }
  }

  Future<bool> addToQueue(dynamic video) async {
    try {
      final source = await _createAudioSource(video);
      if (source != null) {
        await _playlist.add(source);
        if (_player.audioSource != _playlist) {
          await _player.setAudioSource(_playlist);
        }
        return true;
      } else {
        final context = navigatorKey.currentContext;
        if (context != null) {
          showGlassSnackBar(context, 'Failed to add to queue');
        }
        return false;
      }
    } catch (e) {
      debugPrint('Error adding to queue: $e');
      return false;
    }
  }

  Future<AudioSource?> _createAudioSource(dynamic video) async {
    try {
      String videoId;
      String title;
      String artist;
      String artUri;
      String resultType = 'video';
      String? artistId;
      Duration? duration;

      if (video is MuzoItem) {
        if (video.videoId == null) return null;
        videoId = video.videoId!;
        title = video.title;
        artist = video.displayArtist;
        artistId = video.artists?.firstOrNull?.id;
        artUri = video.thumbnails.isNotEmpty ? video.thumbnails.last.url : '';
        resultType = video.resultType;
        if (video.durationSeconds != null) {
          duration = Duration(seconds: video.durationSeconds!);
        }
      } else {
        return null;
      }

      final downloadPath = _storage.getDownloadPath(videoId);
      Uri audioUri;

      if (video.resultType == 'user_track') {
        if (video.audioUrl == null) {
          debugPrint('AudioHandler: user track missing audioUrl');
          return null;
        }
        audioUri = Uri.parse(video.audioUrl!);
      } else if (downloadPath != null && await File(downloadPath).exists()) {
        audioUri = Uri.file(downloadPath);
      } else {
        final streamUrl = await StreamExtractionService.getStreamUrl(
          videoId,
          title: title,
          artist: artist,
          durationSeconds: duration?.inSeconds,
        );
        if (streamUrl == null) {
          debugPrint('AudioHandler: getStreamUrl returned null for $videoId');
          return null;
        }
        audioUri = Uri.parse(streamUrl);
      }

      return AudioSource.uri(
        audioUri,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181 Mobile Safari/537.36',
        },
        tag: MediaItem(
          id: videoId,
          album: "Tunefy",
          title: title,
          artist: artist,
          duration: duration,
          artUri: Uri.parse(artUri),
          extras: {
            'resultType': resultType,
            'artistId': artistId,
            'isSaavn': StreamExtractionService.isSaavnCache[videoId],
            'audioUrl': video.audioUrl,
          },
        ),
      );
    } catch (e) {
      debugPrint('Error creating audio source: $e');
      return null;
    }
  }

  Future<void> playAll(
    List<MuzoItem> results, {
    int startIndex = 0,
    int retryCount = 0,
  }) async {
    try {
      _isInitialLoading = true;
      if (results.isEmpty) {
        return;
      }

      await _playlist.clear();

      // Build a lazy source for every song. Tracks that fail to resolve are
      // auto-skipped by ResolvingAudioSource (empty stream) instead of killing
      // the whole queue, so a 100-song list never stops on one bad track.
      //
      // Songs with a direct audioUrl (Jamendo/Audius/iTunes previews) stream
      // instantly; ytify YouTube ids must be extracted (can take 10s+ and may
      // be unplayable). Reorder so every streamable-by-URL track is played
      // first — otherwise a section whose first cards are dead ytify videos
      // produces seconds of silence before anything is skipped.
      final direct = <MuzoItem>[];
      final extracted = <MuzoItem>[];
      for (final song in results) {
        ((song.audioUrl != null && song.audioUrl!.isNotEmpty)
                ? direct
                : extracted)
            .add(song);
      }
      final ordered = [...direct, ...extracted];
      final startSong = startIndex >= 0 && startIndex < results.length
          ? results[startIndex]
          : null;
      var safeStart = 0;
      if (startSong != null) {
        final i = ordered.indexWhere((s) => identical(s, startSong));
        safeStart = i >= 0 ? i : 0;
      }

      final sources = <AudioSource>[];
      for (final song in ordered) {
        final source = _createLazyAudioSource(song);
        if (source != null) sources.add(source);
      }
      if (sources.isEmpty) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          showGlassSnackBar(context, 'No playable songs found');
        }
        return;
      }

      await _playlist.addAll(sources);

      // Pre-resolve the song that will actually start playing — plus a couple
      // of follow-ups — so tapping a title, Play or Shuffle starts sound
      // promptly instead of stalling while the stream is extracted lazily.
      for (int i = safeStart; i < sources.length && i < safeStart + 3; i++) {
        final source = sources[i];
        if (source is ResolvingAudioSource) {
          unawaited(source.resolve());
        }
      }

      await _player.setAudioSource(
        _playlist,
        initialPosition: Duration.zero,
        initialIndex: safeStart,
        preload: true,
      );

      // Surface play errors instead of failing silently — with a flaky backend
      // a track may refuse to buffer and the user should know why. A rapid
      // re-tap interrupts the previous play() call; that is normal, not an
      // error, so it is ignored.
      _playWithAutoSkip();
    } catch (e) {
      debugPrint('Error playing all (attempt ${retryCount + 1}): $e');
      if (retryCount < 1) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        return playAll(results, startIndex: startIndex, retryCount: retryCount + 1);
      }
      final context = navigatorKey.currentContext;
      if (context != null) {
        showGlassSnackBar(context, 'Playback unavailable right now');
      }
    } finally {
      _isInitialLoading = false;
    }
  }

  /// Plays the current player with silent auto-skip: whenever a track fails
  /// to buffer (flaky backend), the queue advances to the next one instead of
  /// stopping with an error toast. An error snack is only shown when the whole
  /// remaining queue is unplayable — so playback errors stop being a part of
  /// normal listening. A rapid re-tap interrupts play() and is ignored.
  void _playWithAutoSkip({int skipsLeft = 2}) {
    unawaited(_player.play().catchError((Object e) {
      if (e is PlayerInterruptedException) return;
      debugPrint('Playback error ($skipsLeft skips left): $e');
      if (skipsLeft > 0 && _player.hasNext) {
        unawaited(
            _player.seekToNext().then((_) => _playWithAutoSkip(skipsLeft: skipsLeft - 1)));
        return;
      }
      final context = navigatorKey.currentContext;
      if (context != null) {
        showGlassSnackBar(context, 'Playback unavailable right now');
      }
    }));
  }

  AudioSource? _createLazyAudioSource(MuzoItem result) {
    if (result.videoId == null) return null;
    final videoId = result.videoId!;
    final title = result.title;
    final artist = result.displayArtist;
    final artUri =
        result.thumbnails.isNotEmpty ? result.thumbnails.last.url : '';
    final duration = result.durationSeconds != null
        ? Duration(seconds: result.durationSeconds!)
        : null;

    final mediaItem = MediaItem(
      id: videoId,
      album: 'Tunefy',
      title: title,
      artist: artist,
      duration: duration,
      artUri: Uri.parse(artUri),
      extras: {
        'resultType': result.resultType,
        'lazy': true,
        'audioUrl': result.audioUrl,
      },
    );

    return ResolvingAudioSource(
      videoId: videoId,
      storage: _storage,
      tag: mediaItem,
    );
  }

  Future<void> pause() => _player.pause();
  Future<void> seek(Duration position, {int? index}) =>
      _player.seek(position, index: index);
  Future<void> resume() async => _safePlay();

  /// Starts playback, swallowing harmless errors: a rapid re-tap interrupts
  /// play() (PlayerInterruptedException) and a stream that refuses to buffer
  /// is logged, never thrown as an unhandled async error.
  void _safePlay() {
    unawaited(_player.play().catchError((Object e) {
      if (e is PlayerInterruptedException) return;
      debugPrint('Playback error: $e');
    }));
  }

  Future<void> skipToNext() async {
    await _player.seekToNext();
    _safePlay();
  }

  Future<void> skipToPrevious() async {
    await _player.seekToPrevious();
    _safePlay();
  }

  void dispose() {
    // Cancel all stream subscriptions to prevent memory leaks
    _playerStateSubscription?.cancel();
    _androidAudioSessionIdSubscription?.cancel();
    _sequenceStateSubscription?.cancel();
    _currentIndexSubscription?.cancel();
    
    // Dispose notifiers
    isLoadingStream.dispose();
    isLofiModeNotifier.dispose();
    isShuffleModeNotifier.dispose();
    
    // Dispose player last
    _player.dispose();
  }

  Future<void> removeQueueItem(int index) async {
    try {
      await _playlist.removeAt(index);
    } catch (e) {
      debugPrint('Error removing queue item: $e');
    }
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    try {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      await _playlist.move(oldIndex, newIndex);
    } catch (e) {
      debugPrint('Error reordering queue: $e');
    }
  }

  Future<void> clearQueue() async {
    try {
      final currentIndex = _player.currentIndex;
      if (currentIndex != null && _playlist.length > 1) {
        if (currentIndex < _playlist.length - 1) {
          await _playlist.removeRange(currentIndex + 1, _playlist.length);
        }
        if (currentIndex > 0) {
          await _playlist.removeRange(0, currentIndex);
        }
      } else {
        await _playlist.clear();
      }
    } catch (e) {
      debugPrint('Error clearing queue: $e');
    }
  }

  Future<void> playNext(MuzoItem result) async {
    try {
      final index = _player.currentIndex;
      if (index == null) {
        await addToQueue(result);
        return;
      }
      if (result.videoId == null) return;
      final videoId = result.videoId!;
      final title = result.title;
      final artist = result.displayArtist;
      final artistId = result.artists?.firstOrNull?.id;
      final artUri =
          result.thumbnails.isNotEmpty ? result.thumbnails.last.url : '';
      final resultType = result.resultType;
      Duration? duration;
      if (result.durationSeconds != null) {
        duration = Duration(seconds: result.durationSeconds!);
      }

      final downloadPath = _storage.getDownloadPath(videoId);
      Uri audioUri;

      if (downloadPath != null && await File(downloadPath).exists()) {
        audioUri = Uri.file(downloadPath);
      } else {
        final streamUrl = await StreamExtractionService.getStreamUrl(
          videoId,
          title: title,
          artist: artist,
          durationSeconds: duration?.inSeconds,
        );
        if (streamUrl == null) return;
        audioUri = Uri.parse(streamUrl);
      }

      final audioSource = AudioSource.uri(
        audioUri,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181 Mobile Safari/537.36',
        },
        tag: MediaItem(
          id: videoId,
          album: "Tunefy",
          title: title,
          artist: artist,
          duration: duration,
          artUri: Uri.parse(artUri),
          extras: {
            'resultType': resultType,
            'artistId': artistId,
            'isSaavn': StreamExtractionService.isSaavnCache[videoId],
          },
        ),
      );

      await _playlist.insert(index + 1, audioSource);

      final context = navigatorKey.currentContext;
      if (context != null) {
        showGlassSnackBar(context, 'Song added to play next');
      }
    } catch (e) {
      debugPrint('Error playing next: $e');
    }
  }
}

class ResolvingAudioSource extends StreamAudioSource {
  final String videoId;
  final StorageService storage;
  String? _resolvedUrl;
  Future<void>? _resolveFuture;

  ResolvingAudioSource({
    required this.videoId,
    required this.storage,
    super.tag,
  });

  Future<void> resolve() async {
    if (_resolvedUrl != null) return;
    if (_resolveFuture != null) {
      await _resolveFuture;
      return;
    }

    final mediaItem = tag as MediaItem?;
    if (mediaItem?.extras?['resultType'] == 'user_track') {
      _resolvedUrl = mediaItem?.extras?['audioUrl'];
      return;
    }

    final title = mediaItem?.title;
    final artist = mediaItem?.artist;
    final durationSeconds = mediaItem?.duration?.inSeconds;

    final future = StreamExtractionService.getStreamUrl(
      videoId,
      title: title,
      artist: artist,
      durationSeconds: durationSeconds,
    ).then((url) {
      _resolvedUrl = url;
    }).catchError((e) {
      debugPrint('Error pre-resolving track $videoId: $e');
    }).whenComplete(() {
      _resolveFuture = null;
    });

    _resolveFuture = future;
    await future;
  }

  Future<HttpClientResponse> _makeRequest(int? start, int? end) async {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(_resolvedUrl!));
    request.headers.add(
      'User-Agent',
      'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181 Mobile Safari/537.36',
    );

    // just_audio calls request(0, -1) for the whole stream. Sending a Range
    // like "bytes=0--2" makes CDNs (e.g. Saavn) fail the request: always build
    // a valid header and fall back to an open-ended range when unknown.
    if (start != null && start > 0) {
      request.headers.add(
        'Range',
        'bytes=$start-${(end != null && end > start) ? (end - 1) : ""}',
      );
    }

    return await request.close();
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final downloadPath = storage.getDownloadPath(videoId);
    if (downloadPath != null && await File(downloadPath).exists()) {
      final file = File(downloadPath);
      final length = await file.length();
      final s = start ?? 0;
      final e = end ?? length;
      return StreamAudioResponse(
        sourceLength: length,
        contentLength: e - s,
        offset: s,
        contentType: 'audio/mpeg',
        stream: file.openRead(s, e),
      );
    }

    if (_resolvedUrl == null) {
      await resolve();
      if (_resolvedUrl == null) {
        // Skip this track instead of killing the whole queue.
        return _emptyResponse(start);
      }
    }

    // The stream backend is flaky, so a single failed request must never take
    // down playback: retry a couple of times with a short backoff, then skip
    // the track (empty response) instead of throwing.
    HttpClientResponse? response;
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        final r = await _makeRequest(start, end);
        if (r.statusCode == 403 && attempt < 3) {
          debugPrint(
              'ResolvingAudioSource: 403 Forbidden. Refreshing URL...');
          _resolvedUrl = null;
          await resolve();
          if (_resolvedUrl == null) {
            return _emptyResponse(start);
          }
          continue;
        }
        response = r;
        break;
      } catch (e) {
        debugPrint('ResolvingAudioSource request error: $e');
        if (attempt >= 3) {
          return _emptyResponse(start);
        }
        await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
      }
    }

    if (response!.statusCode >= 400) {
      return _emptyResponse(start);
    }

    final contentLength = response.contentLength;
    int sourceLength = contentLength;
    final contentRange = response.headers.value('content-range');
    if (contentRange != null) {
      final parts = contentRange.split('/');
      if (parts.length == 2) {
        sourceLength = int.tryParse(parts[1]) ?? contentLength;
      }
    } else if (response.statusCode == 200 && start == null) {
      sourceLength = contentLength;
    }

    return StreamAudioResponse(
      sourceLength: sourceLength,
      contentLength: contentLength,
      offset: start ?? 0,
      contentType:
          response.headers.contentType?.toString() ?? 'audio/mpeg',
      stream: response,
    );
  }

  /// A zero-length audio response. The player treats it as an instant end-of-
  /// track and advances to the next song, so unplayable tracks are skipped.
  StreamAudioResponse _emptyResponse(int? start) {
    return StreamAudioResponse(
      sourceLength: 0,
      contentLength: 0,
      offset: start ?? 0,
      contentType: 'audio/mpeg',
      stream: const Stream.empty(),
    );
  }
}
