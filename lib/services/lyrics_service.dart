import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class KaraokeSyllable {
  final Duration time;
  final Duration duration;
  final String text;
  const KaraokeSyllable({required this.time, required this.duration, required this.text});
}

class KaraokeLine {
  final Duration lineStart;
  final String fullText;
  final List<KaraokeSyllable> syllables;
  const KaraokeLine({required this.lineStart, required this.fullText, required this.syllables});
}

class Lyrics {
  final int id;
  final String trackName;
  final String artistName;
  final int duration;
  final bool instrumental;
  final String plainLyrics;
  final String syncedLyrics;
  final List<KaraokeLine>? karaokeLines;

  const Lyrics({
    this.id = 0,
    required this.trackName,
    required this.artistName,
    this.duration = 0,
    this.instrumental = false,
    this.plainLyrics = '',
    this.syncedLyrics = '',
    this.karaokeLines,
  });

  factory Lyrics.fromJson(Map<String, dynamic> json) {
    return Lyrics(
      id: json['id'] ?? 0,
      trackName: json['trackName'] ?? '',
      artistName: json['artistName'] ?? '',
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      instrumental: json['instrumental'] ?? false,
      plainLyrics: json['plainLyrics'] ?? '',
      syncedLyrics: json['syncedLyrics'] ?? '',
    );
  }
}

class LyricsService {
  static const String _lrclibBaseUrl = 'https://lrclib.net/api';

  Future<Lyrics?> fetchLyrics(String trackName, String artistName, int duration) async {
    final cleanTrack = _cleanTitle(trackName);
    final cleanArtist = _cleanTitle(artistName);

    final atomixResult = await _fetchFromAtomix(cleanTrack, cleanArtist, duration);
    if (atomixResult != null) return atomixResult;

    return _fetchFromLrclib(cleanTrack, cleanArtist, duration);
  }

  Future<Lyrics?> _fetchFromAtomix(String track, String artist, int duration) async {
    try {
      final uri = Uri.parse('https://lyrics.geeked.wtf/v2/lyrics/get').replace(
        queryParameters: {'title': track, 'artist': artist, 'duration': duration.toString()},
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String responseType = data['type'] ?? '';
        final bool isSupported = (responseType == 'Line' || responseType == 'Word') && data['lyrics'] != null;
        if (isSupported) {
          final List<dynamic> lines = data['lyrics'];
          final StringBuffer syncedBuffer = StringBuffer();
          final StringBuffer plainBuffer = StringBuffer();
          final List<KaraokeLine>? karaokeLines = responseType == 'Word' ? [] : null;

          for (var line in lines) {
            final int rawMs = line['time'] ?? 0;
            final String text = (line['text'] as String? ?? '').trim();
            if (text.isEmpty) continue;
            final lineDuration = Duration(milliseconds: rawMs);
            final minutes = lineDuration.inMinutes.toString().padLeft(2, '0');
            final seconds = (lineDuration.inSeconds % 60).toString().padLeft(2, '0');
            final hundredths = ((lineDuration.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');
            syncedBuffer.writeln('[$minutes:$seconds.$hundredths] $text');
            plainBuffer.writeln(text);

            if (responseType == 'Word') {
              final List<dynamic> syllabi = (line['syllabus'] as List<dynamic>?) ?? [];
              final List<KaraokeSyllable> syllables = syllabi.map((s) {
                return KaraokeSyllable(
                  time: Duration(milliseconds: (s['time'] as num?)?.toInt() ?? rawMs),
                  duration: Duration(milliseconds: (s['duration'] as num?)?.toInt() ?? 300),
                  text: s['text'] as String? ?? '',
                );
              }).toList();
              karaokeLines!.add(KaraokeLine(
                lineStart: Duration(milliseconds: rawMs),
                fullText: text,
                syllables: syllables.isEmpty
                    ? [KaraokeSyllable(time: Duration(milliseconds: rawMs), duration: const Duration(milliseconds: 2000), text: text)]
                    : syllables,
              ));
            }
          }

          if (plainBuffer.isNotEmpty) {
            debugPrint('LyricsService: Found via Atomix ($responseType)');
            return Lyrics(
              trackName: track,
              artistName: artist,
              duration: duration,
              plainLyrics: plainBuffer.toString(),
              syncedLyrics: syncedBuffer.toString(),
              karaokeLines: karaokeLines,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('LyricsService: Atomix error: $e');
    }
    return null;
  }

  Future<Lyrics?> _fetchFromLrclib(String track, String artist, int duration) async {
    try {
      final uri = Uri.parse('$_lrclibBaseUrl/get').replace(
        queryParameters: {'track_name': track, 'artist_name': artist},
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['plainLyrics'] != null || data['syncedLyrics'] != null) {
          return Lyrics.fromJson(data);
        }
      } else if (response.statusCode == 404) {
        return _searchLrclib(track, artist, duration);
      }
    } catch (e) {
      debugPrint('LyricsService: LRCLIB error: $e');
      return _searchLrclib(track, artist, duration);
    }
    return null;
  }

  Future<Lyrics?> _searchLrclib(String track, String artist, int duration) async {
    try {
      final uri = Uri.parse('$_lrclibBaseUrl/search').replace(
        queryParameters: {'track_name': track, 'artist_name': artist},
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        if (list.isEmpty) return null;
        Lyrics? bestMatch;
        int minDiff = 1000000;
        for (var item in list) {
          final l = Lyrics.fromJson(item);
          final diff = (l.duration - duration).abs();
          if (l.plainLyrics.isEmpty && l.syncedLyrics.isEmpty) continue;
          if (diff < minDiff) {
            minDiff = diff;
            bestMatch = l;
          }
        }
        if (minDiff <= 5 && bestMatch != null) return bestMatch;
      }
    } catch (e) {
      debugPrint('LyricsService: LRCLIB search error: $e');
    }
    return null;
  }

  String _cleanTitle(String text) {
    if (text.isEmpty) return text;
    var clean = text;
    final videoPattern = RegExp(r'\s*[\(\[](official|video|audio|lyrics|lyric|hd|hq|4k|mv|music video|full audio)[\)\]]', caseSensitive: false);
    clean = clean.replaceAll(videoPattern, '');
    final featPattern = RegExp(r'\s+(ft\.|feat\.|featuring)\s+', caseSensitive: false);
    if (featPattern.hasMatch(clean)) clean = clean.split(featPattern).first;
    clean = clean.replaceAll(' - Topic', '');
    return clean.trim();
  }
}
