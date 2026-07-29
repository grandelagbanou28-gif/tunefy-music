import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:muzoapi/youtube_stream_provider.dart';
import 'package:tunefy/services/premium_service.dart';
import 'package:tunefy/services/server_config_service.dart';

class StreamExtractionService {
  static final Map<String, bool> isSaavnCache = {};
  static final ValueNotifier<String?> currentStreamUrl = ValueNotifier(null);

  static String _cleanArtist(String artist) {
    String cleaned = artist;
    cleaned = cleaned.replaceAll(RegExp(r'\s*-\s*Topic$', caseSensitive: false), '');
    final featPattern = RegExp(r'\s*\b(?:feat\.?|ft\.?|featuring)\b.*$', caseSensitive: false);
    cleaned = cleaned.replaceAll(featPattern, '');
    final primaryArtistPattern = RegExp(r'^([^,&]+)');
    final match = primaryArtistPattern.firstMatch(cleaned);
    if (match != null) cleaned = match.group(1)!;
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.isNotEmpty ? cleaned : artist;
  }

  static String _cleanTitle(String title, String artist) {
    String cleaned = title;
    final bracketNoise = RegExp(r'\s*[([][^\])]*(?:video|audio|lyric|lyrics|mv|hd|4k|live|remix|official|music)[^\])]*[\])]', caseSensitive: false);
    cleaned = cleaned.replaceAll(bracketNoise, '');
    final standaloneNoise = RegExp(r'\s*\b(?:official video|official audio|music video|lyric video|lyrics|official|mv)\b', caseSensitive: false);
    cleaned = cleaned.replaceAll(standaloneNoise, '');
    final featPattern = RegExp(r'\s*\b(?:feat\.?|ft\.?|featuring)\b.*$', caseSensitive: false);
    cleaned = cleaned.replaceAll(featPattern, '');
    if (artist.isNotEmpty) {
      final cleanedArtist = _cleanArtist(artist);
      if (cleaned.contains('-')) {
        final parts = cleaned.split('-');
        final firstPart = parts[0].trim();
        if (firstPart.toLowerCase() == cleanedArtist.toLowerCase()) {
          cleaned = parts.skip(1).join('-').trim();
        }
      }
    }
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.isNotEmpty ? cleaned : title;
  }

  static Future<String?> getSaavnStreamUrl(String title, String artist, {int? durationSeconds}) async {
    try {
      final cleanTitle = _cleanTitle(title, artist);
      final cleanArtist = _cleanArtist(artist);

      final localUrl = await ServerConfigService.getSaavnStreamUrlLocal(cleanTitle, cleanArtist);
      if (localUrl != null) {
        debugPrint('SaavnExtraction: [Local] Found stream');
        return localUrl;
      }

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
      ));
      String? durationString;
      if (durationSeconds != null && durationSeconds > 0) {
        final minutes = durationSeconds ~/ 60;
        final seconds = durationSeconds % 60;
        durationString = "$minutes:${seconds.toString().padLeft(2, '0')}";
      }
      final queryParams = {
        'title': cleanTitle,
        'artist': cleanArtist,
        if (durationString != null) 'duration': durationString,
      };
      final response = await dio.get<String>(
        'https://fast-saavn.vercel.app/',
        queryParameters: queryParams,
        options: Options(responseType: ResponseType.plain, validateStatus: (status) => true),
      );
      if (response.statusCode == 200 && response.data != null) {
        final path = response.data!.trim();
        if (path.isNotEmpty && !path.toLowerCase().contains('error') && !path.toLowerCase().contains('fail')) {
          final fullUrl = 'https://aac.saavncdn.com/${path}_320.mp4';
          debugPrint('SaavnExtraction: [Remote] Found stream');
          return fullUrl;
        }
      }
    } catch (e) {
      debugPrint('SaavnExtraction Error: $e');
    }
    return null;
  }

  static Future<String?> _getStreamViaPipedInstance(String instance, String videoId) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
      ));
      final response = await dio.get<Map<String, dynamic>>(
        '$instance/streams/$videoId',
        options: Options(responseType: ResponseType.json),
      );
      final data = response.data;
      if (data == null) return null;
      final audioStreams = data['audioStreams'] as List?;
      if (audioStreams == null || audioStreams.isEmpty) return null;
      final sorted = List<Map<String, dynamic>>.from(audioStreams)
        ..sort((a, b) => (b['bitrate'] ?? 0).compareTo(a['bitrate'] ?? 0));
      final selected = PremiumService.isPremium
          ? sorted.first
          : (sorted.length > 2 ? sorted[1] : sorted.last);
      final url = selected['url'] as String?;
      if (url != null && url.isNotEmpty) {
        debugPrint('StreamExtraction: [Piped] Found stream via $instance');
        return url;
      }
    } catch (e) {
      debugPrint('StreamExtraction: [Piped] $instance error: $e');
    }
    return null;
  }

  static Future<String?> _racePipedInstances(String videoId) async {
    final instances = [
      'https://pipedapi.kavin.rocks',
      'https://pipedapi.adminforge.de',
      'https://piped-api.privacy.com.de',
      'https://api.piped.privacydev.net',
    ];
    return _raceAny(instances.map((inst) => _getStreamViaPipedInstance(inst, videoId)).toList());
  }

  static Future<String?> _getYoutubeStreamUrlViaInnerTube(String videoId) async {
    try {
      final yt = CustomInnerTube();
      final streamInfo = await yt.player(videoId);
      if (streamInfo.audioStreams.isNotEmpty) {
        final sortedStreams = streamInfo.audioStreams.toList()
          ..sort((a, b) => b.bitrate.compareTo(a.bitrate));
        final selectedStream = PremiumService.isPremium
            ? sortedStreams.first
            : (sortedStreams.length > 2 ? sortedStreams[1] : sortedStreams.last);
        debugPrint('StreamExtraction: [InnerTube] Selected stream: ${selectedStream.bitrate} bps');
        return selectedStream.url;
      }
    } catch (e) {
      debugPrint('StreamExtraction: [InnerTube] Error: $e');
    }
    return null;
  }

  static Future<String?> _raceAny(List<Future<String?>> futures) async {
    final completer = Completer<String?>();
    int completed = 0;
    for (final f in futures) {
      f.then((url) {
        if (completer.isCompleted) return;
        if (url != null) {
          completer.complete(url);
        } else {
          completed++;
          if (completed >= futures.length) completer.complete(null);
        }
      }).catchError((_) {
        if (completer.isCompleted) return;
        completed++;
        if (completed >= futures.length) completer.complete(null);
      });
    }
    if (futures.isEmpty) return null;
    return completer.future;
  }

  static bool _isNumeric(String s) =>
      s.isNotEmpty && s.codeUnits.every((c) => c >= 48 && c <= 57);

  static Future<String?> getStreamUrl(
    String videoId, {
    String? title,
    String? artist,
    int? durationSeconds,
  }) async {
    final stopwatch = Stopwatch()..start();

    if (videoId.startsWith('deezer_') && title != null && artist != null) {
      debugPrint('StreamExtraction: deezer_ ID → racing all sources');

      final futures = <Future<String?>>[
        getSaavnStreamUrl(title, artist, durationSeconds: durationSeconds),
        _getYoutubeStreamUrlViaInnerTube(videoId),
      ];

      final url = await _raceAny(futures);
      if (url != null) {
        debugPrint('StreamExtraction: deezer_ won in ${stopwatch.elapsedMilliseconds}ms');
        currentStreamUrl.value = url;
        return url;
      }
      return null;
    }

    if (_isNumeric(videoId) && title != null && artist != null) {
      // iTunes numeric ID — skip Piped/InnerTube, try Saavn by title+artist only
      debugPrint('StreamExtraction: numeric ID → Saavn only');
      final url = await getSaavnStreamUrl(title, artist, durationSeconds: durationSeconds);
      if (url != null) {
        debugPrint('StreamExtraction: Saavn won in ${stopwatch.elapsedMilliseconds}ms');
        currentStreamUrl.value = url;
        return url;
      }
      return null;
    }

    if (!videoId.startsWith('deezer_')) {
      final futures = <Future<String?>>[
        _racePipedInstances(videoId),
        _getYoutubeStreamUrlViaInnerTube(videoId),
      ];
      if (title != null && artist != null) {
        futures.add(getSaavnStreamUrl(title, artist, durationSeconds: durationSeconds));
      }

      final url = await _raceAny(futures);
      if (url != null) {
        debugPrint('StreamExtraction: YouTube ID won in ${stopwatch.elapsedMilliseconds}ms');
        currentStreamUrl.value = url;
        return url;
      }
    }

    isSaavnCache[videoId] = false;
    final yt = YoutubeExplode();
    try {
      final manifest = await yt.videos.streamsClient.getManifest(
        videoId,
        ytClients: [YoutubeApiClient.androidVr],
      );
      Iterable<AudioOnlyStreamInfo> audioStreams = manifest.audioOnly;
      if (Platform.isMacOS || Platform.isIOS) {
        final mp4Streams = audioStreams.where((s) => s.container == StreamContainer.mp4);
        if (mp4Streams.isNotEmpty) audioStreams = mp4Streams;
      }
      if (audioStreams.isNotEmpty) {
        final sortedStreams = audioStreams.toList()
          ..sort((a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond));
        final url = sortedStreams.first.url.toString();
        debugPrint('StreamExtraction: [YoutubeExplode] Won in ${stopwatch.elapsedMilliseconds}ms');
        currentStreamUrl.value = url;
        return url;
      }
    } catch (e) {
      debugPrint('StreamExtraction: [YoutubeExplode] Error: $e');
    } finally {
      yt.close();
    }
    return null;
  }
}

class CustomInnerTube extends InnerTube {
  CustomInnerTube({super.options});

  @override
  String get baseUrl => 'https://www.youtube.com/youtubei/v1/';

  @override
  Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      'User-Agent': 'com.google.android.apps.youtube.music/7.27.52 (Linux; U; Android 14; en_US; sdk_gphone64_x86_64 Build/UE1A.230829.036.A1) gzip',
      'X-Goog-Api-Key': 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30',
    };
  }

  @override
  Map<String, dynamic> getContextPayload() {
    return {
      'context': {
        'client': {
          'clientName': 'ANDROID_MUSIC',
          'clientVersion': '7.27.52',
          'androidSdkVersion': 34,
          'hl': 'en',
          'gl': 'US',
          'osName': 'Android',
          'osVersion': '14',
          'deviceMake': 'Google',
          'deviceModel': 'sdk_gphone64_x86_64',
        }
      },
    };
  }

  @override
  Future<Map<String, dynamic>> makeRequest(String endpoint, Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl$endpoint?prettyPrint=false');
    final response = await http.post(uri, headers: getHeaders(), body: jsonEncode(payload));
    if (response.statusCode >= 400) {
      throw Exception('HTTP error! status: ${response.statusCode}');
    }
    return jsonDecode(response.body);
  }
}
