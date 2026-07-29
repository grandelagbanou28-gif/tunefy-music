import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:tunefy/models/track.dart';

class LikedService {
  static const _boxName = 'liked_songs';
  static final LikedService _instance = LikedService._();
  factory LikedService() => _instance;
  LikedService._();

  Box get _box => Hive.box(_boxName);

  List<Track> getAll() {
    final raw = _box.get('tracks', defaultValue: <String>[]);
    final list = List<String>.from(raw);
    return list.map((s) => Track.fromMap(jsonDecode(s))).toList();
  }

  bool isLiked(String? videoId) {
    if (videoId == null) return false;
    return _box.containsKey(videoId);
  }

  Future<void> toggle(Track track) async {
    final id = track.videoId;
    if (id == null) return;
    if (isLiked(id)) {
      await _box.delete(id);
      await _box.put('tracks', _rebuildList());
    } else {
      await _box.put(id, jsonEncode(track.toMap()));
      await _box.put('tracks', _rebuildList());
    }
  }

  Future<void> add(Track track) async {
    final id = track.videoId;
    if (id == null || isLiked(id)) return;
    await _box.put(id, jsonEncode(track.toMap()));
    await _box.put('tracks', _rebuildList());
  }

  Future<void> remove(String? videoId) async {
    if (videoId == null || !isLiked(videoId)) return;
    await _box.delete(videoId);
    await _box.put('tracks', _rebuildList());
  }

  List<String> _rebuildList() {
    return _box.keys
        .where((k) => k != 'tracks')
        .map((k) => _box.get(k) as String)
        .toList();
  }
}
