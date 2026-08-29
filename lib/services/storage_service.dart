import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/models/user_data.dart';
import 'package:muzo/services/listening_stats_service.dart';
import 'package:muzo/services/muzo_api_service.dart';
import 'package:muzo/services/supabase_store.dart';
import 'package:muzo/services/ytm_home.dart';
import 'package:http/http.dart' as http;

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class StorageService {
  static const String _settingsBoxName = 'settings';
  static const String _downloadsBoxName = 'downloads';
  static const String _artistImagesBoxName = 'artist_images';
  static const String _userAvatarBoxName = 'user_avatar';
  static const String _historyBoxName = 'history_cache';
  static const String _homeBoxName = 'home_cache';
  static const String _favoritesBoxName = 'favorites_cache';
  static const String _searchHistoryBoxName = 'search_history';
  static const String _subscriptionsBoxName = 'subscriptions_cache';
  static const String _playlistsBoxName = 'playlists_cache';
  static const String _foldersBoxName = 'folders_cache';
  static const String _pinsBoxName = 'pins_cache';
  static const String _qrHistoryBoxName = 'qr_history';

  MuzoApiService? _apiInstance;
  MuzoApiService get _api {
    _apiInstance ??= MuzoApiService(this);
    return _apiInstance!;
  }

  SupabaseStore? _supabase;
  SupabaseStore? get supabase => _supabase;

  // In-memory state with Notifiers
  final ValueNotifier<List<MuzoItem>> _historyNotifier = ValueNotifier([]);
  final ValueNotifier<List<MuzoItem>> _favoritesNotifier = ValueNotifier([]);
  final ValueNotifier<List<Channel>> _subscriptionsNotifier = ValueNotifier([]);
  final ValueNotifier<List<Playlist>> _playlistsNotifier =
      ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> _qrHistoryNotifier =
      ValueNotifier([]);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

  Future<void> init() async {
    if (kIsWeb) {
      Hive.init(''); // IndexedDB backend on web (path_provider unavailable)
    } else {
      await Hive.initFlutter();
    }
    await Hive.openBox(_settingsBoxName);
    await Hive.openBox(_downloadsBoxName);
    await Hive.openBox(_artistImagesBoxName);
    await Hive.openBox(_userAvatarBoxName);
    await Hive.openBox(_historyBoxName);
    await Hive.openBox(_homeBoxName);
    await Hive.openBox(_searchHistoryBoxName);
    await Hive.openBox(_foldersBoxName);
    await Hive.openBox(_pinsBoxName);
    await Hive.openBox(_qrHistoryBoxName);
    await stats.init();

    // Load QR history
    final qrBox = Hive.box(_qrHistoryBoxName);
    final cachedQr = qrBox.get('list');
    if (cachedQr != null) {
      try {
        _qrHistoryNotifier.value =
            (cachedQr as List).map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        debugPrint('Error loading QR history: $e');
      }
    }

    // Load cached history
    final historyBox = Hive.box(_historyBoxName);
    final cachedHistory = historyBox.get('list');
    if (cachedHistory != null) {
      try {
        _historyNotifier.value = (cachedHistory as List)
            .map((e) => MuzoItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (e) {
        debugPrint('Error loading cached history: $e');
      }
    }

    // Load cached favorites
    await Hive.openBox(_favoritesBoxName);
    final favoritesBox = Hive.box(_favoritesBoxName);
    final cachedFavorites = favoritesBox.get('list');
    if (cachedFavorites != null) {
      try {
        _favoritesNotifier.value = (cachedFavorites as List)
            .map((e) => MuzoItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (e) {
        debugPrint('Error loading cached favorites: $e');
      }
    }

    // Load cached subscriptions
    await Hive.openBox(_subscriptionsBoxName);
    final subscriptionsBox = Hive.box(_subscriptionsBoxName);
    final cachedSubscriptions = subscriptionsBox.get('list');
    if (cachedSubscriptions != null) {
      try {
        _subscriptionsNotifier.value = (cachedSubscriptions as List)
            .map((e) => Channel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (e) {
        debugPrint('Error loading cached subscriptions: $e');
      }
    }

    // Load cached playlists
    await Hive.openBox(_playlistsBoxName);
    final playlistsBox = Hive.box(_playlistsBoxName);
    final cachedPlaylists = playlistsBox.get('list');
    if (cachedPlaylists != null) {
      try {
        _playlistsNotifier.value = (cachedPlaylists as List)
            .map((e) => Playlist.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (e) {
        debugPrint('Error loading cached playlists: $e');
      }
    }

    // API is now lazily initialized
    // Supabase seed + merge happens in the background (await-free so the app
    // starts immediately even offline).
    _initSupabase();
    debugPrint('StorageService initialized');
  }

  // ─── Supabase (durable DB layer, local Hive always wins as cache) ─────
  Future<void> _initSupabase() async {
    try {
      final store = SupabaseStore();
      _supabase = store;
      await store.init();
      debugPrint('Supabase ready: ${store.ready} uid=${store.uid}');
      if (!store.ready) return;
      await _mergeRemote();
    } catch (e) {
      debugPrint('Supabase unavailable (local-only mode): $e');
      _supabase = null;
    }
  }

  /// Runs [dbOp] on Supabase first; falls back to the legacy HTTP API when
  /// Supabase is unavailable or rejects the write.
  Future<void> _dbSync(
    Future<void> Function(SupabaseStore s) dbOp,
    Future<void> Function() fallback,
  ) async {
    final s = _supabase;
    if (s != null && s.ready) {
      try {
        await dbOp(s);
        return;
      } catch (e) {
        debugPrint('Supabase sync failed, falling back: $e');
      }
    }
    try {
      await fallback();
    } catch (e) {
      debugPrint('Legacy API sync failed: $e');
    }
  }

  /// One-shot bidirectional merge at startup: union of local (Hive) and remote
  /// (Supabase) data, then the merged result is pushed back to the DB.
  Future<void> _mergeRemote() async {
    final s = _supabase;
    if (s == null) return;
    await _mergeFavorites(s);
    await _mergeHistory(s);
    await _mergeSubscriptions(s);
    await _mergePlaylists(s);
  }

  Future<void> _mergeFavorites(SupabaseStore s) async {
    try {
      final remote = await s.fetchFavorites();
      final local = _favoritesNotifier.value;
      final merged = List<MuzoItem>.from(local);
      final seen = local.map((e) => e.videoId).toSet();
      for (final r in remote) {
        if (r.videoId != null && !seen.contains(r.videoId)) {
          merged.add(r);
          seen.add(r.videoId);
        }
      }
      if (merged.length != local.length) {
        _favoritesNotifier.value = merged;
        _saveFavoritesToCache(merged);
      }
      for (final m in merged) {
        if (m.videoId == null) continue;
        if (remote.any((r) => r.videoId == m.videoId)) continue;
        try {
          await s.addToFavorites(m);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Merge favorites failed: $e');
    }
  }

  Future<void> _mergeHistory(SupabaseStore s) async {
    try {
      final remote = await s.fetchHistory();
      final local = _historyNotifier.value;
      final merged = List<MuzoItem>.from(local);
      final seen = local.map((e) => e.videoId).toSet();
      for (final r in remote) {
        if (r.videoId != null && !seen.contains(r.videoId)) {
          if (merged.length >= SupabaseStore.maxHistoryLength) break;
          merged.add(r);
          seen.add(r.videoId);
        }
      }
      if (merged.length != local.length) {
        _historyNotifier.value = merged;
        _saveHistoryToCache(merged);
      }
      for (final m in merged) {
        if (m.videoId == null) continue;
        if (remote.any((r) => r.videoId == m.videoId)) continue;
        try {
          await s.addToHistory(m);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Merge history failed: $e');
    }
  }

  Future<void> _mergeSubscriptions(SupabaseStore s) async {
    try {
      final remote = await s.fetchSubscriptions();
      final local = _subscriptionsNotifier.value;
      String keyOf(Channel c) => '${c.channelId ?? ''}|${c.name}';
      final merged = List<Channel>.from(local);
      final seen = local.map(keyOf).toSet();
      for (final r in remote) {
        final k = keyOf(r);
        if (!seen.contains(k)) {
          merged.add(r);
          seen.add(k);
        }
      }
      if (merged.length != local.length) {
        _subscriptionsNotifier.value = merged;
        _saveSubscriptionsToCache(merged);
      }
      for (final m in merged) {
        final k = keyOf(m);
        if (remote.any((r) => keyOf(r) == k)) continue;
        try {
          await s.addSubscription(m);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Merge subscriptions failed: $e');
    }
  }

  Future<void> _mergePlaylists(SupabaseStore s) async {
    try {
      final remote = await s.fetchPlaylists();
      final local = _playlistsNotifier.value;
      final merged = List<Playlist>.from(local);
      final seen = local.map((p) => p.name).toSet();
      for (final r in remote) {
        if (!seen.contains(r.name)) {
          merged.add(r);
          seen.add(r.name);
        }
      }
      if (merged.length != local.length) {
        _playlistsNotifier.value = merged;
        _savePlaylistsToCache(merged);
      }
      for (final m in merged) {
        if (remote.any((r) => r.name == m.name)) continue;
        try {
          await s.savePlaylist(m);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Merge playlists failed: $e');
    }
  }

  final ListeningStatsService stats = ListeningStatsService();

  Future<void> refreshAll({bool silent = false}) async {
    if (!silent) isLoadingNotifier.value = true;

    try {
      final userData = await _api.getUserData();

      // Update User Info
      await setUserInfo(
        userData.user.username,
        userData.user.email,
        avatarUrl: userData.user.avatar,
      );

      // Update History
      _historyNotifier.value = userData.history;
      _saveHistoryToCache(userData.history);

      // Update Favorites
      _favoritesNotifier.value = userData.favorites;
      _saveFavoritesToCache(userData.favorites);

      // Update Subscriptions
      _subscriptionsNotifier.value = userData.subscriptions;
      _saveSubscriptionsToCache(userData.subscriptions);

      // Update Playlists
      _playlistsNotifier.value = userData.playlists;
      _savePlaylistsToCache(userData.playlists);
    } catch (e) {
      debugPrint('Error refreshing data: $e');
      // Fallback to individual calls if consolidated fails?
      // Or just log error. The requirement implies replacing it.
      // We can keep individual calls as fallback if we wanted resilience, but let's stick to the plan.
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  // Listenables for UI
  ValueListenable<List<MuzoItem>> get historyListenable => _historyNotifier;
  ValueListenable<List<MuzoItem>> get favoritesListenable =>
      _favoritesNotifier;
  ValueListenable<List<Channel>> get subscriptionsListenable =>
      _subscriptionsNotifier;
  ValueListenable<List<Playlist>> get playlistsListenable =>
      _playlistsNotifier;

  // Synchronous getters for current state
  List<MuzoItem> getHistory() => _historyNotifier.value;
  List<MuzoItem> getFavorites() => _favoritesNotifier.value;
  List<Channel> getSubscriptions() => _subscriptionsNotifier.value;
  List<String> getPlaylistNames() => _playlistsNotifier.value.map((p) => p.name).toList();
  List<MuzoItem> getPlaylistSongs(String name) {
    try {
      return _playlistsNotifier.value.firstWhere((p) => p.name == name).songs;
    } catch (e) {
      return [];
    }
  }

  // History
  Future<void> addToHistory(MuzoItem result) async {
    if (result.resultType == 'user_track') {
      return;
    }
    // Optimistic update
    final current = List<MuzoItem>.from(_historyNotifier.value);
    current.insert(0, result);
    _historyNotifier.value = current;
    _saveHistoryToCache(current);

    try {
      await _dbSync(
        (s) => s.addToHistory(result),
        () => _api.addToHistory(result),
      );
    } catch (e) {
      debugPrint('Error adding to history API: $e');
      // We don't set errorNotifier here to avoid spamming user on every song play
    }
  }


  Future<void> removeFromHistory(String videoId) async {
    isLoadingNotifier.value = true;
    // Optimistic update
    final current = List<MuzoItem>.from(_historyNotifier.value);
    current.removeWhere((item) => item.videoId == videoId);
    _historyNotifier.value = current;
    _saveHistoryToCache(current);

    try {
      await _dbSync(
        (s) => s.removeFromHistory(videoId),
        () => _api.removeFromHistory(videoId),
      );
    } catch (e) {
      errorNotifier.value = 'Failed to remove from history: $e';
      // Revert optimistic update?
      // For history, maybe not strictly necessary to revert as it's less critical,
      // but strictly speaking we should.
      // However, fetching the item back is hard without knowing what it was exactly (we removed it).
      // We could keep a reference to the removed item.
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  Future<void> clearHistory() async {
    isLoadingNotifier.value = true;
    try {
      await _dbSync((s) => s.clearHistory(), () => _api.clearHistory());
      _historyNotifier.value = [];
      _saveHistoryToCache([]);
    } catch (e) {
      errorNotifier.value = 'Failed to clear history: $e';
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  // Playlists

  Future<void> createPlaylist(String name) async {
    // Playlists are auto-created by the API when a song is added.
    // Just update local state optimistically (and seed the DB row).
    final current = List<Playlist>.from(_playlistsNotifier.value);
    if (!current.any((p) => p.name == name)) {
      final playlist = Playlist(
        id: 0,
        name: name,
        createdAt: DateTime.now().toIso8601String(),
        songCount: 0,
        songs: [],
      );
      current.add(playlist);
      _playlistsNotifier.value = current;
      _savePlaylistsToCache(current);
      await _dbSync((s) => s.savePlaylist(playlist), () async {});
    }
  }

  Future<void> deletePlaylist(String name) async {
    isLoadingNotifier.value = true;
    try {
      await _dbSync(
        (s) => s.deletePlaylist(name),
        () => _api.deletePlaylist(name),
      );
      final current = List<Playlist>.from(_playlistsNotifier.value);
      current.removeWhere((p) => p.name == name);
      _playlistsNotifier.value = current;
      _savePlaylistsToCache(current);
    } catch (e) {
      errorNotifier.value = 'Failed to delete playlist: $e';
    } finally {
      isLoadingNotifier.value = false;
    }
  }


  Future<void> addToPlaylist(String name, MuzoItem result) async {
    final current = List<Playlist>.from(_playlistsNotifier.value);
    final playlistIndex = current.indexWhere((p) => p.name == name);

    if (playlistIndex != -1) {
      final playlist = current[playlistIndex];
      final songs = List<MuzoItem>.from(playlist.songs);

      if (!songs.any((s) => s.videoId == result.videoId)) {
        isLoadingNotifier.value = true;
        try {
          final updated = Playlist(
            id: playlist.id,
            name: playlist.name,
            createdAt: playlist.createdAt,
            songCount: songs.length + 1,
            songs: [...songs, result],
          );
          await _dbSync(
            (s) => s.savePlaylist(updated),
            () => _api.addToPlaylist(name, result),
          );
          songs.add(result);
          current[playlistIndex] = updated;
          _playlistsNotifier.value = current;
          _savePlaylistsToCache(current);
        } catch (e) {
          errorNotifier.value = 'Failed to add to playlist: $e';
        } finally {
          isLoadingNotifier.value = false;
        }
      }
    }
  }

  Future<void> removeFromPlaylist(String name, String videoId) async {
    final current = List<Playlist>.from(_playlistsNotifier.value);
    final playlistIndex = current.indexWhere((p) => p.name == name);

    if (playlistIndex != -1) {
      final playlist = current[playlistIndex];
      final songs = List<MuzoItem>.from(playlist.songs);

      // Optimistic
      songs.removeWhere((s) => s.videoId == videoId);
      current[playlistIndex] = Playlist(
        id: playlist.id,
        name: playlist.name,
        createdAt: playlist.createdAt,
        songCount: songs.length,
        songs: songs,
      );
      _playlistsNotifier.value = current;
      _savePlaylistsToCache(current);

      isLoadingNotifier.value = true;
      try {
        await _dbSync(
          (s) => s.savePlaylist(current[playlistIndex]),
          () => _api.removeSongFromPlaylist(name, videoId),
        );
      } catch (e) {
        errorNotifier.value = 'Failed to remove from playlist: $e';
      } finally {
        isLoadingNotifier.value = false;
      }
    }
  }

  // ─── Folders ───
  List<Map<String, dynamic>> getFolders() {
    final box = Hive.box(_foldersBoxName);
    final data = box.get('list');
    if (data == null) return [];
    try {
      return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> createFolder(String name) async {
    final folders = getFolders();
    if (folders.any((f) => f['name'] == name)) return;
    folders.insert(0, {'name': name, 'playlists': <String>[]});
    final box = Hive.box(_foldersBoxName);
    await box.put('list', folders);
  }

  Future<void> deleteFolder(String name) async {
    final folders = getFolders();
    folders.removeWhere((f) => f['name'] == name);
    final box = Hive.box(_foldersBoxName);
    await box.put('list', folders);
  }

  Future<void> renameFolder(String oldName, String newName) async {
    final folders = getFolders();
    final idx = folders.indexWhere((f) => f['name'] == oldName);
    if (idx == -1) return;
    folders[idx]['name'] = newName;
    final box = Hive.box(_foldersBoxName);
    await box.put('list', folders);
  }

  Future<void> addPlaylistToFolder(String folderName, String playlistName) async {
    final folders = getFolders();
    final idx = folders.indexWhere((f) => f['name'] == folderName);
    if (idx == -1) return;
    final playlists = List<String>.from(folders[idx]['playlists'] ?? []);
    if (!playlists.contains(playlistName)) {
      playlists.add(playlistName);
      folders[idx]['playlists'] = playlists;
      final box = Hive.box(_foldersBoxName);
      await box.put('list', folders);
    }
  }

  Future<void> removePlaylistFromFolder(String folderName, String playlistName) async {
    final folders = getFolders();
    final idx = folders.indexWhere((f) => f['name'] == folderName);
    if (idx == -1) return;
    final playlists = List<String>.from(folders[idx]['playlists'] ?? []);
    playlists.remove(playlistName);
    folders[idx]['playlists'] = playlists;
    final box = Hive.box(_foldersBoxName);
    await box.put('list', folders);
  }

  // ─── Pins ───
  List<String> getPinnedItems() {
    final box = Hive.box(_pinsBoxName);
    final data = box.get('list');
    if (data == null) return [];
    try {
      return List<String>.from(data);
    } catch (e) {
      return [];
    }
  }

  bool isPinned(String itemId) => getPinnedItems().contains(itemId);

  Future<void> pinItem(String itemId) async {
    final pins = getPinnedItems();
    if (pins.contains(itemId) || pins.length >= 20) return;
    pins.insert(0, itemId);
    final box = Hive.box(_pinsBoxName);
    await box.put('list', pins);
  }

  Future<void> unpinItem(String itemId) async {
    final pins = getPinnedItems();
    pins.remove(itemId);
    final box = Hive.box(_pinsBoxName);
    await box.put('list', pins);
  }

  // Favorites
  bool isFavorite(String videoId) {
    return _favoritesNotifier.value.any((s) => s.videoId == videoId);
  }

  Future<void> toggleFavorite(MuzoItem result) async {
    final current = List<MuzoItem>.from(_favoritesNotifier.value);
    final index = current.indexWhere((s) => s.videoId == result.videoId);

    // Optimistic local update so the UI reflects the change immediately.
    if (index != -1) {
      current.removeAt(index);
    } else {
      current.insert(0, result);
    }
    _favoritesNotifier.value = current;
    _saveFavoritesToCache(current);

    try {
      if (index != -1) {
        await _dbSync(
          (s) => s.removeFromFavorites(result.videoId!),
          () => _api.removeFromFavorites(result.videoId!),
        );
      } else {
        await _dbSync(
          (s) => s.addToFavorites(result),
          () => _api.addToFavorites(result),
        );
      }
    } catch (e) {
      debugPrint('Failed to sync favorites: $e');
      errorNotifier.value = 'Failed to sync favorites: $e';
    }
  }

  /// Batch-sets [songs] as favorites (or removes them) with an optimistic local
  /// update first, then syncs to the backend in the background.
  Future<void> setFavoriteBatch(
    List<MuzoItem> songs, {
    required bool favorite,
  }) async {
    final current = List<MuzoItem>.from(_favoritesNotifier.value);
    final targetIds = songs
        .where((s) => s.videoId != null)
        .map((s) => s.videoId!)
        .toSet();

    if (favorite) {
      for (final s in songs) {
        if (s.videoId != null &&
            !current.any((c) => c.videoId == s.videoId)) {
          current.insert(0, s);
        }
      }
    } else {
      current.removeWhere((c) => c.videoId != null && targetIds.contains(c.videoId));
    }

    _favoritesNotifier.value = current;
    _saveFavoritesToCache(current);

    for (final s in songs) {
      if (s.videoId == null) continue;
      try {
        await _dbSync(
          (db) => favorite
              ? db.addToFavorites(s)
              : db.removeFromFavorites(s.videoId!),
          () => favorite
              ? _api.addToFavorites(s)
              : _api.removeFromFavorites(s.videoId!),
        );
      } catch (e) {
        debugPrint('Failed to sync favorite "${s.title}": $e');
      }
    }
  }

  // Downloads (Local only)
  Box get _downloadsBox => Hive.box(_downloadsBoxName);
  ValueListenable<Box> get downloadsListenable => _downloadsBox.listenable();

  List<Map<String, dynamic>> getDownloads() {
    final dynamic data = _downloadsBox.get('list');
    if (data == null) return [];

    try {
      final List<dynamic> jsonList = data;
      return jsonList.map((json) => Map<String, dynamic>.from(json)).toList();
    } catch (e) {
      return [];
    }
  }

  bool isDownloaded(String videoId) {
    final downloads = getDownloads();
    return downloads.any((d) => d['videoId'] == videoId);
  }

  String? getDownloadPath(String videoId) {
    final downloads = getDownloads();
    final item = downloads.firstWhere(
      (d) => d['videoId'] == videoId,
      orElse: () => {},
    );
    return item.isNotEmpty ? item['path'] : null;
  }

  Future<void> addDownload(MuzoItem result, String path) async {
    final downloads = getDownloads();
    if (!downloads.any((d) => d['videoId'] == result.videoId)) {
      downloads.insert(0, {
        'videoId': result.videoId,
        'result': result.toJson(),
        'path': path,
        'timestamp': DateTime.now().toIso8601String(),
      });
      await _downloadsBox.put('list', downloads);
    }
  }

  Future<void> removeDownload(String videoId) async {
    final downloads = getDownloads();
    downloads.removeWhere((d) => d['videoId'] == videoId);
    await _downloadsBox.put('list', downloads);
  }

  // Subscriptions
  bool isSubscribed(String channelId) {
    return _subscriptionsNotifier.value.any(
      (s) => s.channelId == channelId || s.name == channelId,
    );
  }

  Future<void> toggleSubscription(Channel channel) async {
    isLoadingNotifier.value = true;
    final current = List<Channel>.from(_subscriptionsNotifier.value);
    final index = current.indexWhere(
      (s) => s.channelId == channel.channelId || s.name == channel.name,
    );

    try {
      if (index != -1) {
        // Unsubscribe — use channelId or name as the identifier
        final id = channel.channelId ?? channel.name;
        await _dbSync(
          (s) => s.removeSubscription(id),
          () => _api.removeSubscription(id),
        );
        current.removeAt(index);
        _subscriptionsNotifier.value = current;
      } else {
        // Subscribe
        await _dbSync(
          (s) => s.addSubscription(channel),
          () => _api.addSubscription(channel),
        );
        current.insert(0, channel);
        _subscriptionsNotifier.value = current;
      }
      _saveSubscriptionsToCache(current);
    } catch (e) {
      errorNotifier.value = 'Failed to update subscription: $e';
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  // Artist Images (Local Cache)
  Box get _artistImagesBox => Hive.box(_artistImagesBoxName);
  ValueListenable<Box> get artistImagesListenable =>
      _artistImagesBox.listenable();

  String? getArtistImage(String artistId) {
    return _artistImagesBox.get(artistId);
  }

  Future<void> setArtistImage(String artistId, String url) async {
    await _artistImagesBox.put(artistId, url);
  }

  final _fetchingArtists = <String>{};

  Future<void> fetchAndCacheArtistImage(String artistId) async {
    if (_fetchingArtists.contains(artistId)) return;
    if (getArtistImage(artistId) != null) return;

    _fetchingArtists.add(artistId);

    try {
      final apiService = _api;
      final details = await apiService.getArtistDetails(artistId);
      if (details != null && details.artistAvatar.isNotEmpty) {
        await setArtistImage(artistId, details.artistAvatar);
      } else {
        await setArtistImage(artistId, 'INVALID_ARTIST');
      }
    } catch (e) {
      debugPrint('Error fetching artist image for $artistId: $e');
    } finally {
      _fetchingArtists.remove(artistId);
    }
  }

  // Settings
  Box get _settingsBox => Hive.box(_settingsBoxName);
  ValueListenable<Box> get settingsListenable => _settingsBox.listenable();

  String? get rapidApiKey => _settingsBox.get('rapidApiKey');

  Future<void> setRapidApiKey(String? value) async {
    if (value == null || value.isEmpty) {
      await _settingsBox.delete('rapidApiKey');
    } else {
      await _settingsBox.put('rapidApiKey', value);
    }
  }

  String get rapidApiCountryCode =>
      _settingsBox.get('rapidApiCountryCode', defaultValue: 'IN');
  Future<void> setRapidApiCountryCode(String code) =>
      _settingsBox.put('rapidApiCountryCode', code);

  // Browse All categories chosen by the user (Search screen).
  List<String> get chosenCategories =>
      ((_settingsBox.get('chosenCategories', defaultValue: <String>[]) as List)
              .map((e) => e.toString()))
          .toList();

  Future<void> setChosenCategories(List<String> value) =>
      _settingsBox.put('chosenCategories', value);

  // User Info
  String? get username => _settingsBox.get('username');
  String? get email => _settingsBox.get('email');
  String? get avatarUrl => _settingsBox.get('avatarUrl');
  String? get authToken => _settingsBox.get('authToken');

  // External API keys (free tiers)
  String? get lastFmApiKey => _settingsBox.get('lastFmApiKey') ?? '';
  String? get geniusToken => _settingsBox.get('geniusToken') ?? 'uQBl_OnFhA0E1tEm4JjdQhG5YY1u-d5jJRrv_Mre5rEVSwzbGHs-dUofNOSKDYhy';
  String? get musixmatchApiKey => _settingsBox.get('musixmatchApiKey') ?? '';
  String? get jamendoKey => _settingsBox.get('jamendoKey') ?? '';

  Future<void> setUsername(String value) async {
    await _settingsBox.put('username', value);
  }

  Future<void> setUserInfo(
    String username,
    String email, {
    String? avatarUrl,
  }) async {
    await _settingsBox.put('username', username);
    await _settingsBox.put('email', email);
    if (avatarUrl != null) {
      await _settingsBox.put('avatarUrl', avatarUrl);
      // Fetch avatar if it's a new URL or not cached
      fetchAndCacheUserAvatar();
    }
  }

  Future<void> setAuthToken(String token) async {
    await _settingsBox.put('authToken', token);
    // Refresh data when token is set (login). We don't await this so it doesn't block the UI.
    refreshAll();
  }

  Future<void> clearUserSession() async {
    await _settingsBox.delete('username');
    await _settingsBox.delete('email');
    await _settingsBox.delete('avatarUrl');
    await _settingsBox.delete('authToken');
    await _userAvatarBox.delete('avatar_svg');
    // Clear in-memory state
    _playlistsNotifier.value = [];
    _subscriptionsNotifier.value = [];
  }

  // User Avatar (Local Cache)
  Box get _userAvatarBox => Hive.box(_userAvatarBoxName);
  ValueListenable<Box> get userAvatarListenable => _userAvatarBox.listenable();

  String? getUserAvatar() {
    return _userAvatarBox.get('avatar_svg');
  }

  Future<void> fetchAndCacheUserAvatar() async {
    final user = username;
    final urlOverride = avatarUrl;
    if (user == null && urlOverride == null) return;

    final url = urlOverride ?? 'https://api.dicebear.com/9.x/rings/svg?seed=$user';
    
    // Only fetch and cache if it's an SVG (DiceBear or explicitly .svg)
    if (url.contains('dicebear') || url.contains('.svg')) {
      try {
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          await _userAvatarBox.put('avatar_svg', response.body);
        } else {
          debugPrint('Failed to fetch avatar: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Error fetching user avatar: $e');
      }
    } else {
      // If it's a regular image format (JPG, PNG, etc.), clear the SVG cache
      // to ensure the UI falls back to network image correctly.
      await _userAvatarBox.delete('avatar_svg');
    }
  }

  // Auto Queue Setting
  bool get isAutoQueueEnabled =>
      _settingsBox.get('isAutoQueueEnabled', defaultValue: true);
  Future<void> setAutoQueueEnabled(bool value) =>
      _settingsBox.put('isAutoQueueEnabled', value);

  // Lofi Settings
  double get lofiSpeed => _settingsBox.get('lofiSpeed', defaultValue: 0.85);
  Future<void> setLofiSpeed(double value) async {
    await _settingsBox.put('lofiSpeed', value);
  }

  double get lofiPitch => _settingsBox.get('lofiPitch', defaultValue: 0.85);
  Future<void> setLofiPitch(double value) async {
    await _settingsBox.put('lofiPitch', value);
  }

  // App Font
  String get appFontFamily => _settingsBox.get('appFontFamily', defaultValue: 'AR One Sans');
  Future<void> setAppFontFamily(String value) =>
      _settingsBox.put('appFontFamily', value);

  // App Language
  String get appLanguage => _settingsBox.get('appLanguage', defaultValue: 'english');
  Future<void> setAppLanguage(String value) async {
    await _settingsBox.put('appLanguage', value);
  }

  // Playback preferences (persisted)
  bool get autoplayEnabled =>
      _settingsBox.get('autoplayEnabled', defaultValue: true);
  Future<void> setAutoplayEnabled(bool value) =>
      _settingsBox.put('autoplayEnabled', value);

  bool get crossfadeEnabled =>
      _settingsBox.get('crossfadeEnabled', defaultValue: false);
  Future<void> setCrossfadeEnabled(bool value) =>
      _settingsBox.put('crossfadeEnabled', value);

  bool get gaplessEnabled =>
      _settingsBox.get('gaplessEnabled', defaultValue: true);
  Future<void> setGaplessEnabled(bool value) =>
      _settingsBox.put('gaplessEnabled', value);

  bool get loudnessNormalizationEnabled =>
      _settingsBox.get('loudnessNormalizationEnabled', defaultValue: false);
  Future<void> setLoudnessNormalizationEnabled(bool value) =>
      _settingsBox.put('loudnessNormalizationEnabled', value);

  // Downloads preferences
  bool get wifiOnlyDownloads =>
      _settingsBox.get('wifiOnlyDownloads', defaultValue: true);
  Future<void> setWifiOnlyDownloads(bool value) =>
      _settingsBox.put('wifiOnlyDownloads', value);

  bool get cellularDownloadsEnabled =>
      _settingsBox.get('cellularDownloadsEnabled', defaultValue: false);
  Future<void> setCellularDownloadsEnabled(bool value) =>
      _settingsBox.put('cellularDownloadsEnabled', value);

  String get storageLocation =>
      _settingsBox.get('storageLocation', defaultValue: 'Internal');
  Future<void> setStorageLocation(String value) =>
      _settingsBox.put('storageLocation', value);

  // Notifications preferences
  bool get appNotificationsEnabled =>
      _settingsBox.get('appNotificationsEnabled', defaultValue: true);
  Future<void> setAppNotificationsEnabled(bool value) =>
      _settingsBox.put('appNotificationsEnabled', value);

  bool get newReleasesNotifications =>
      _settingsBox.get('newReleasesNotifications', defaultValue: true);
  Future<void> setNewReleasesNotifications(bool value) =>
      _settingsBox.put('newReleasesNotifications', value);

  bool get followedArtistNotifications =>
      _settingsBox.get('followedArtistNotifications', defaultValue: true);
  Future<void> setFollowedArtistNotifications(bool value) =>
      _settingsBox.put('followedArtistNotifications', value);

  bool get recommendationsNotifications =>
      _settingsBox.get('recommendationsNotifications', defaultValue: false);
  Future<void> setRecommendationsNotifications(bool value) =>
      _settingsBox.put('recommendationsNotifications', value);

  bool get promotionsNotifications =>
      _settingsBox.get('promotionsNotifications', defaultValue: false);
  Future<void> setPromotionsNotifications(bool value) =>
      _settingsBox.put('promotionsNotifications', value);

  // Privacy preferences
  bool get isProfilePublic =>
      _settingsBox.get('isProfilePublic', defaultValue: true);
  Future<void> setIsProfilePublic(bool value) =>
      _settingsBox.put('isProfilePublic', value);

  bool get isHistoryVisible =>
      _settingsBox.get('isHistoryVisible', defaultValue: true);
  Future<void> setIsHistoryVisible(bool value) =>
      _settingsBox.put('isHistoryVisible', value);

  // Security preferences
  bool get biometricAuthEnabled =>
      _settingsBox.get('biometricAuthEnabled', defaultValue: false);
  Future<void> setBiometricAuthEnabled(bool value) =>
      _settingsBox.put('biometricAuthEnabled', value);

  bool get pinLockEnabled =>
      _settingsBox.get('pinLockEnabled', defaultValue: false);
  Future<void> setPinLockEnabled(bool value) =>
      _settingsBox.put('pinLockEnabled', value);

  String? get localPin => _settingsBox.get('localPin');
  Future<void> setLocalPin(String? value) async {
    if (value == null || value.isEmpty) {
      await _settingsBox.delete('localPin');
    } else {
      await _settingsBox.put('localPin', value);
    }
  }

  String? get localPasswordHash => _settingsBox.get('localPasswordHash');
  Future<void> setLocalPasswordHash(String? value) async {
    if (value == null || value.isEmpty) {
      await _settingsBox.delete('localPasswordHash');
    } else {
      await _settingsBox.put('localPasswordHash', value);
    }
  }

  // Profile photo (local file path)
  String? get profilePhotoPath => _settingsBox.get('profilePhotoPath');
  Future<void> setProfilePhotoPath(String? value) async {
    if (value == null || value.isEmpty) {
      await _settingsBox.delete('profilePhotoPath');
    } else {
      await _settingsBox.put('profilePhotoPath', value);
    }
  }

  // Updates
  String? get lastUpdateCheck => _settingsBox.get('lastUpdateCheck');
  Future<void> setLastUpdateCheck(String value) =>
      _settingsBox.put('lastUpdateCheck', value);

  /// Total size on disk (bytes) of all downloaded songs.
  Future<int> downloadsTotalBytes() async {
    var total = 0;
    for (final d in getDownloads()) {
      final path = d['path'];
      if (path is String && path.isNotEmpty) {
        try {
          final f = File(path);
          if (await f.exists()) total += await f.length();
        } catch (_) {}
      }
    }
    return total;
  }

  Future<void> clearDownloads() async {
    await _downloadsBox.delete('list');
  }

  // App Links
  bool get handleAppLinks => _settingsBox.get('handleAppLinks', defaultValue: true);
  Future<void> setHandleAppLinks(bool value) async {
    await _settingsBox.put('handleAppLinks', value);
  }

  // YTM Home Page Sections
  bool get showYtmHome => _settingsBox.get('showYtmHome', defaultValue: true);
  Future<void> setShowYtmHome(bool value) async {
    await _settingsBox.put('showYtmHome', value);
  }

  // Cache Helpers
  Future<void> _saveHistoryToCache(List<MuzoItem> history) async {
    try {
      final box = Hive.box(_historyBoxName);
      await box.put('list', history.map((e) => e.toCacheJson()).toList());
    } catch (e) {
      debugPrint('Error saving history cache: $e');
    }
  }

  Future<void> _saveFavoritesToCache(List<MuzoItem> favorites) async {
    try {
      final box = Hive.box(_favoritesBoxName);
      await box.put('list', favorites.map((e) => e.toCacheJson()).toList());
    } catch (e) {
      debugPrint('Error saving favorites cache: $e');
    }
  }

  Future<void> _saveSubscriptionsToCache(
    List<Channel> subscriptions,
  ) async {
    try {
      final box = Hive.box(_subscriptionsBoxName);
      await box.put('list', subscriptions.map((e) => e.toJson()).toList());
    } catch (e) {
      debugPrint('Error saving subscriptions cache: $e');
    }
  }

  Future<void> _savePlaylistsToCache(
    List<Playlist> playlists,
  ) async {
    try {
      final box = Hive.box(_playlistsBoxName);
      await box.put('list', playlists.map((e) => e.toJson()).toList());
    } catch (e) {
      debugPrint('Error saving playlists cache: $e');
    }
  }

  // Home Screen Cache
  Box get _homeBox => Hive.box(_homeBoxName);

  List<HomeSection> getHomeCache() {
    final cached = _homeBox.get('sections');
    if (cached != null) {
      try {
        return (cached as List)
            .map((e) => HomeSection.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (e) {
        debugPrint('Error loading home cache: $e');
      }
    }
    return [];
  }

  Future<void> setHomeCache(List<HomeSection> sections) async {
    try {
      await _homeBox.put('sections', sections.map((e) => e.toJson()).toList());
    } catch (e) {
      debugPrint('Error saving home cache: $e');
    }
  }

  // Search History
  Box get _searchHistoryBox => Hive.box(_searchHistoryBoxName);

  List<String> getSearchHistory() {
    final dynamic data = _searchHistoryBox.get('list');
    if (data == null) return [];
    try {
      return (data as List).cast<String>();
    } catch (e) {
      return [];
    }
  }

  Future<void> addSearchQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final current = getSearchHistory();
    current.removeWhere((q) => q.toLowerCase() == trimmed.toLowerCase());
    current.insert(0, trimmed);
    if (current.length > 20) current.removeRange(20, current.length);
    await _searchHistoryBox.put('list', current);
  }

  Future<void> clearSearchHistory() async {
    await _searchHistoryBox.delete('list');
  }

  // Cache Helpers for Settings
  Future<void> clearSongsCache() async {
    final historyBox = Hive.box(_historyBoxName);
    await historyBox.delete('list');
    final favoritesBox = Hive.box(_favoritesBoxName);
    await favoritesBox.delete('list');
  }

  Future<void> clearArtistCache() async {
    await _artistImagesBox.clear();
  }

  Future<void> clearAlbumCache() async {
    await _homeBox.clear();
  }

  Future<void> clearPlaylistCache() async {
    final playlistsBox = Hive.box(_playlistsBoxName);
    await playlistsBox.delete('list');
  }

  // ─── QR History ───
  ValueNotifier<List<Map<String, dynamic>>> get qrHistoryNotifier =>
      _qrHistoryNotifier;

  List<Map<String, dynamic>> getQrHistory() => _qrHistoryNotifier.value;

  Future<void> addQrHistory({
    required String value,
    String? source,
  }) async {
    final entry = {
      'value': value,
      'source': source ?? 'unknown',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    final current = List<Map<String,dynamic>>.from(_qrHistoryNotifier.value);
    current.removeWhere((e) => e['value'] == value);
    current.insert(0, entry);
    if (current.length > 30) current.removeRange(30, current.length);
    _qrHistoryNotifier.value = current;
    final box = Hive.box(_qrHistoryBoxName);
    await box.put('list', current);
  }

  Future<void> clearQrHistory() async {
    _qrHistoryNotifier.value = [];
    final box = Hive.box(_qrHistoryBoxName);
    await box.delete('list');
  }
}
