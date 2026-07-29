import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tunefy/models/home_track.dart';
import 'package:tunefy/services/search_service.dart';
import 'package:tunefy/helpers/tunefy_helpers.dart';
import 'package:tunefy/theme/tunefy_colors.dart';
import 'package:tunefy/ui/collection_detail_page.dart';

enum SearchTypeFilter { all, songs, artists, albums, playlists }

class EmbeddedSearchScreen extends StatefulWidget {
  final String? initialQuery;
  const EmbeddedSearchScreen({super.key, this.initialQuery});

  @override
  State<EmbeddedSearchScreen> createState() => _EmbeddedSearchScreenState();
}

class _EmbeddedSearchScreenState extends State<EmbeddedSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<SearchResult> _results = [];
  List<SearchSuggestion> _suggestions = [];
  List<SearchResult> _recentSearches = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  SearchTypeFilter _activeFilter = SearchTypeFilter.all;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    if (widget.initialQuery != null) {
      _controller.text = widget.initialQuery!;
      _doSearch(widget.initialQuery!);
    }
  }

  void _loadRecentSearches() {
    try {
      final box = Hive.box('settings');
      final list = box.get('recent_searches', defaultValue: []);
      _recentSearches = (list as List).map((e) {
        final m = Map<String, dynamic>.from(e);
        return SearchResult(
          id: m['id'] ?? '',
          title: m['title'] ?? '',
          subtitle: m['subtitle'] ?? '',
          type: m['type'] ?? 'song',
          imageUrl: m['imageUrl'],
          videoId: m['videoId'],
          browseId: m['browseId'],
          duration: m['duration'],
        );
      }).toList();
    } catch (_) {
      _recentSearches = [];
    }
  }

  void _saveRecentSearches() {
    try {
      final box = Hive.box('settings');
      box.put('recent_searches', _recentSearches.map((r) => {
        'id': r.id, 'title': r.title, 'subtitle': r.subtitle,
        'type': r.type, 'imageUrl': r.imageUrl, 'videoId': r.videoId,
        'browseId': r.browseId, 'duration': r.duration,
      }).toList());
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _doSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _isLoading = true; _hasSearched = true; _suggestions = []; });
    try {
      final results = await SearchService.search(query);
      if (mounted) {
        setState(() { _results = results; _isLoading = false; });
        if (results.isNotEmpty) {
          final first = results.first;
          if (!_recentSearches.any((r) => r.id == first.id)) {
            _recentSearches.insert(0, first);
            if (_recentSearches.length > 20) _recentSearches.removeLast();
            _saveRecentSearches();
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _getSuggestions(String query) async {
    if (query.trim().length < 2) { if (mounted) setState(() => _suggestions = []); return; }
    try {
      final suggestions = await SearchService.getSuggestions(query);
      if (mounted) setState(() => _suggestions = suggestions);
    } catch (e) {
      debugPrint('EmbeddedSearch: _getSuggestions error: $e');
    }
  }

  void _playSearchResult(SearchResult result) async {
    if (result.type == 'song' || result.videoId != null) {
      if (result.videoId == null && result.saavnId == null) return;
      final track = HomeTrack(
        videoId: result.videoId ?? 'deezer_${result.saavnId ?? result.id}',
        title: result.title,
        artist: result.subtitle,
        duration: result.duration ?? '0:00',
        imageUrl: result.imageUrl,
      );
      selectTrack(track);
      Navigator.pop(context);
      return;
    }

    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) =>
      const Center(child: CircularProgressIndicator(color: TunefyColors.green, strokeWidth: 2)));

    List<HomeTrack> tracks = [];
    if (result.type == 'album' && result.saavnId != null) {
      tracks = await SearchService.fetchSaavnAlbumTracks(result.saavnId!);
    } else if (result.type == 'playlist' && result.saavnId != null) {
      tracks = await SearchService.fetchSaavnPlaylistTracks(result.saavnId!);
    } else if (result.type == 'artist' && result.saavnId != null) {
      tracks = await SearchService.fetchSaavnArtistTracks(result.saavnId!);
    }

    if (mounted) Navigator.pop(context);

    if (tracks.isNotEmpty && mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => CollectionDetailPage(
          heroTrack: tracks.first,
          allTracks: tracks,
          albumTitle: result.title,
          albumImage: result.imageUrl,
          isPlaylistView: true,
          heroTrackList: tracks,
        ),
      ));
    }
  }

  List<SearchResult> get _filteredResults {
    if (_activeFilter == SearchTypeFilter.all) return _results;
    return _results.where((r) {
      switch (_activeFilter) {
        case SearchTypeFilter.songs: return r.type == 'song' || r.type == 'video' || r.videoId != null;
        case SearchTypeFilter.artists: return r.type == 'artist';
        case SearchTypeFilter.albums: return r.type == 'album';
        case SearchTypeFilter.playlists: return r.type == 'playlist';
        default: return true;
      }
    }).toList();
  }

  String _filterLabel(SearchTypeFilter f) {
    switch (f) {
      case SearchTypeFilter.all: return 'Tous';
      case SearchTypeFilter.songs: return 'Titres';
      case SearchTypeFilter.artists: return 'Artistes';
      case SearchTypeFilter.albums: return 'Albums';
      case SearchTypeFilter.playlists: return 'Playlists';
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'album': return Icons.album;
      case 'artist': return Icons.person;
      case 'playlist': return Icons.queue_music;
      default: return Icons.music_note;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _controller.text.isNotEmpty;
    return Scaffold(
      backgroundColor: TunefyColors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(color: TunefyColors.darkCard, borderRadius: BorderRadius.circular(8)),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: true,
                        style: const TextStyle(fontFamily: 'AM', fontSize: 15, color: TunefyColors.white),
                        decoration: InputDecoration(
                          hintText: 'Rechercher...',
                          hintStyle: const TextStyle(fontFamily: 'AM', fontSize: 15, color: TunefyColors.grey),
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search, color: TunefyColors.grey, size: 20),
                          prefixIconConstraints: const BoxConstraints(minWidth: 40),
                          suffixIcon: hasQuery
                              ? GestureDetector(
                                  onTap: () {
                                    _controller.clear();
                                    setState(() { _results = []; _suggestions = []; _hasSearched = false; _activeFilter = SearchTypeFilter.all; });
                                    _focusNode.requestFocus();
                                  },
                                  child: const Icon(Icons.close, color: TunefyColors.grey, size: 20),
                                )
                              : null,
                        ),
                        onChanged: (v) { setState(() {}); _getSuggestions(v); },
                        onSubmitted: _doSearch,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () { haptic(); Navigator.pop(context); },
                    child: const Text('Annuler', style: TextStyle(fontFamily: 'AM', fontSize: 15, color: TunefyColors.white)),
                  ),
                ],
              ),
            ),
            if (_hasSearched && _results.isNotEmpty) ...[
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: SearchTypeFilter.values.length,
                  itemBuilder: (ctx, i) {
                    final f = SearchTypeFilter.values[i];
                    final active = _activeFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () { haptic(); setState(() => _activeFilter = f); },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: active ? TunefyColors.white : TunefyColors.darkCard,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(_filterLabel(f), style: TextStyle(
                              fontFamily: 'AB', fontSize: 13,
                              color: active ? TunefyColors.black : TunefyColors.white,
                            )),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            Expanded(
              child: Stack(
                children: [
                  if (!_hasSearched)
                    _recentSearches.isNotEmpty
                        ? _buildRecentSearches()
                        : const Center(child: Text('Tapez pour rechercher', style: TextStyle(fontFamily: 'AM', fontSize: 15, color: TunefyColors.grey))),
                  if (_hasSearched)
                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: TunefyColors.green, strokeWidth: 2))
                        : _filteredResults.isEmpty
                            ? const Center(child: Text('Aucun résultat', style: TextStyle(fontFamily: 'AM', fontSize: 15, color: TunefyColors.grey)))
                            : _buildResults(),
                  if (!_hasSearched && _suggestions.isNotEmpty)
                    Positioned(
                      top: 0, left: 0, right: 0, bottom: 0,
                      child: Container(color: TunefyColors.black, child: _buildSuggestions()),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: _suggestions.length,
      itemBuilder: (ctx, i) {
        final s = _suggestions[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: const Icon(Icons.search, color: TunefyColors.grey, size: 20),
          title: Text(s.query, style: const TextStyle(fontFamily: 'AM', fontSize: 15, color: TunefyColors.white)),
          onTap: () {
            haptic();
            _controller.text = s.query;
            _doSearch(s.query);
          },
        );
      },
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Recherches récentes', style: TextStyle(
            fontFamily: 'AB', fontSize: 16, color: TunefyColors.white, fontWeight: FontWeight.w700,
          )),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: _recentSearches.length,
            itemBuilder: (ctx, i) {
              final r = _recentSearches[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: ClipRRect(
                  borderRadius: r.type == 'artist' ? BorderRadius.circular(24) : BorderRadius.circular(4),
                  child: r.imageUrl != null
                      ? CachedNetworkImage(imageUrl: r.imageUrl!, width: 48, height: 48, fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _recentIcon(r))
                      : _recentIcon(r),
                ),
                title: Text(r.title, style: const TextStyle(fontFamily: 'AB', fontSize: 15, color: TunefyColors.white),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(r.subtitle, style: const TextStyle(fontFamily: 'AM', fontSize: 13, color: TunefyColors.grey),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: GestureDetector(
                  onTap: () { haptic(); setState(() { _recentSearches.removeAt(i); _saveRecentSearches(); }); },
                  child: const Icon(Icons.close, color: TunefyColors.grey, size: 18),
                ),
                onTap: () { haptic(); _playSearchResult(r); },
              );
            },
          ),
        ),
        if (_recentSearches.isNotEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              child: GestureDetector(
                onTap: () { haptic(); setState(() { _recentSearches.clear(); _saveRecentSearches(); }); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: TunefyColors.darkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: TunefyColors.grey.withValues(alpha: 0.3)),
                  ),
                  child: const Text('Effacer les recherches récentes', style: TextStyle(
                    fontFamily: 'AB', fontSize: 13, color: TunefyColors.white, fontWeight: FontWeight.w600,
                  )),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _recentIcon(SearchResult r) {
    return Container(width: 48, height: 48, color: TunefyColors.darkCard,
      child: Icon(r.type == 'artist' ? Icons.person : Icons.music_note, color: TunefyColors.grey, size: 20));
  }

  Widget _buildResults() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: _filteredResults.length,
      itemBuilder: (ctx, i) {
        final r = _filteredResults[i];
        final isArtist = r.type == 'artist';
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: ClipRRect(
            borderRadius: isArtist ? BorderRadius.circular(24) : BorderRadius.circular(4),
            child: r.imageUrl != null
                ? CachedNetworkImage(imageUrl: r.imageUrl!, width: 48, height: 48, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _resultIcon(r))
                : _resultIcon(r),
          ),
          title: Text(r.title, style: const TextStyle(fontFamily: 'AB', fontSize: 15, color: TunefyColors.white),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Row(
            children: [
              Icon(_typeIcon(r.type), size: 12, color: TunefyColors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(r.subtitle, style: const TextStyle(fontFamily: 'AM', fontSize: 13, color: TunefyColors.grey),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          trailing: r.videoId != null
              ? GestureDetector(
                  onTap: () { haptic(); _playSearchResult(r); },
                  child: const Icon(Icons.play_circle_outline, color: TunefyColors.white, size: 28),
                )
              : null,
          onTap: () { haptic(); _playSearchResult(r); },
        );
      },
    );
  }

  Widget _resultIcon(SearchResult r) {
    return Container(width: 48, height: 48, color: TunefyColors.darkCard,
      child: Icon(r.type == 'artist' ? Icons.person : Icons.music_note, color: TunefyColors.grey, size: 20));
  }
}
