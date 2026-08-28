import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/services/muzo_api_service.dart';

/// Curated clip queries — short music videos across the app's genres. The
/// feed mixes every query so vertical swiping always lands on something new.
const List<String> kClipQueries = [
  'rap clip officiel',
  'afrobeats music video',
  'amapiano video',
  'pop clip',
  'rumba congolaise clip',
  'gospel clip',
  'dancehall video',
  'rap francais clip',
  'musique arabe clip',
  'latin music video',
  'jazz live session',
  'electronic music video',
  'metal live clip',
  'reggae video',
  'soul live performance',
];

final clipsFeedProvider =
    StateNotifierProvider<ClipsFeedNotifier, AsyncValue<List<MuzoItem>>>(
        (ref) => ClipsFeedNotifier(ref));

class ClipsFeedNotifier extends StateNotifier<AsyncValue<List<MuzoItem>>> {
  ClipsFeedNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadMore();
  }

  final Ref _ref;
  int _nextQuery = 0;
  bool _fetching = false;
  static const int _batchQueries = 3;

  final Set<String> _ids = {};

  /// Fetches the next batch of genre queries and appends the new clips.
  Future<void> loadMore() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final api = _ref.read(muzoApiServiceProvider);
      final added = <MuzoItem>[];
      for (var i = 0; i < _batchQueries; i++) {
        if (_nextQuery >= kClipQueries.length) break;
        final q = kClipQueries[_nextQuery++];
        try {
          final res = await api.search(q, filter: 'videos');
          for (final item in res.results) {
            // Keep it a "clip": real videos, roughly one minute, deduped.
            final dur = item.durationSeconds ?? 0;
            if (item.videoId == null) continue;
            if (dur > 0 && (dur < 15 || dur > 55)) continue;
            if (_ids.contains(item.videoId)) continue;
            _ids.add(item.videoId!);
            added.add(item);
          }
        } catch (_) {
          // One dead genre query must not kill the feed.
        }
      }

      final current = state.value ?? const <MuzoItem>[];
      state = AsyncValue.data([...current, ...added]);
    } catch (e, st) {
      if ((state.value ?? const []).isEmpty) {
        state = AsyncValue.error(e, st);
      }
    } finally {
      _fetching = false;
    }
  }

  /// True when the user swiped close to the end and more clips are needed.
  bool get shouldLoadMore {
    final list = state.value;
    return list != null && list.length - _lastRequestedIndex < 8;
  }

  int _lastRequestedIndex = 0;

  void onPageChanged(int index) {
    _lastRequestedIndex = index;
    if (shouldLoadMore) {
      if (_nextQuery >= kClipQueries.length) {
        // Recycle through the queries with a different order so the feed
        // keeps growing ("des milliers de clips").
        _ids.clear();
        _nextQuery = (index ~/ kClipQueries.length) % kClipQueries.length;
      }
      loadMore();
    }
  }
}
