import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muzo/l10n/app_localizations.dart';
import 'package:muzo/providers/player_provider.dart';
import 'package:muzo/services/storage_service.dart';
import 'package:muzo/providers/search_provider.dart';
import 'package:muzo/widgets/spotify_chips.dart';
import 'package:muzo/widgets/spotify_back_button.dart';
import 'package:muzo/widgets/spotify_search_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LibrarySearchScreen extends ConsumerStatefulWidget {
  const LibrarySearchScreen({super.key});

  @override
  ConsumerState<LibrarySearchScreen> createState() => _LibrarySearchScreenState();
}

class _LibrarySearchScreenState extends ConsumerState<LibrarySearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  Timer? _debounce;
  List<String> _recent = [];

  static const _recentKey = 'library_search_recent';

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _recent = prefs.getStringList(_recentKey) ?? []);
    }
  }

  Future<void> _saveRecent(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _recent.remove(q);
    _recent.insert(0, q);
    if (_recent.length > 20) _recent = _recent.sublist(0, 20);
    await prefs.setStringList(_recentKey, _recent);
    if (mounted) setState(() {});
  }

  Future<void> _clearRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentKey);
    if (mounted) setState(() => _recent = []);
  }

  void _onChanged(String value) {
    final q = value.trim();
    _debounce?.cancel();
    setState(() => _query = q);
    if (q.isEmpty) {
      ref.read(searchQueryProvider.notifier).state = '';
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(searchQueryProvider.notifier).state = q;
    });
  }

  void _submit(String value) {
    _saveRecent(value);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final storage = ref.watch(storageServiceProvider);

    return Scaffold(
      backgroundColor: spotifyBlack,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Back + Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
              child: Row(
                children: [
                  const SpotifyBackButton(),
                  Expanded(
                    child: SpotifySearchBar(
                      controller: _controller,
                      autofocus: true,
                      onChanged: _onChanged,
                      onSubmitted: _submit,
                      hintText: 'Search in Your Library',
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _query.isEmpty ? _buildDefaultContent(l10n, storage) : _buildSearchResults(l10n, storage),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultContent(AppLocalizations l10n, StorageService storage) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 130),
      children: [
        const SizedBox(height: 72),
        // Find your favorites — centered
        const Icon(
          Icons.favorite_outline,
          color: spotifyLightGrey,
          size: 56,
        ),
        const SizedBox(height: 18),
        const Center(
          child: Text(
            'Find your favorites',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: spotifyWhite,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Search for playlists, artists, albums, and podcasts.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: spotifyLightGrey,
            ),
          ),
        ),
        if (_recent.isNotEmpty) ...[
          const SizedBox(height: 36),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Recent',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: spotifyWhite,
              ),
            ),
          ),
          for (final term in _recent)
            ListTile(
              dense: true,
              onTap: () {
                _controller.text = term;
                _controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: term.length),
                );
                _onChanged(term);
                _saveRecent(term);
              },
              leading: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.history, color: spotifyLightGrey, size: 20),
              ),
              title: Text(term,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: spotifyWhite, fontSize: 15)),
              trailing: GestureDetector(
                onTap: () {
                  setState(() => _recent.remove(term));
                  SharedPreferences.getInstance().then(
                    (prefs) => prefs.setStringList(_recentKey, _recent),
                  );
                },
                child: const Icon(Icons.close, color: spotifyLightGrey, size: 18),
              ),
            ),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: _clearRecent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Clear recent',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchResults(AppLocalizations l10n, StorageService storage) {
    final q = _query.toLowerCase();

    // Search playlists
    final playlistNames = storage.getPlaylistNames();
    final matchedPlaylistNames = playlistNames.where((n) => n.toLowerCase().contains(q)).toList();

    // Search favorites
    final favorites = storage.getFavorites();
    final matchedFavorites = favorites.where((f) =>
        f.title.toLowerCase().contains(q) ||
        f.displayArtist.toLowerCase().contains(q)).toList();

    final hasResults = matchedPlaylistNames.isNotEmpty || matchedFavorites.isNotEmpty;

    if (!hasResults) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, color: spotifyLightGrey.withOpacity(0.4), size: 48),
            const SizedBox(height: 12),
            Text(
              'No results for "$_query"',
              style: TextStyle(color: spotifyLightGrey.withOpacity(0.6), fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 130),
      children: [
        if (matchedPlaylistNames.isNotEmpty) ...[
          _sectionHeader('Playlists'),
          ...matchedPlaylistNames.map((name) => ListTile(
                onTap: () {},
                leading: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: spotifyDarkGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.playlist_play, color: spotifyLightGrey, size: 24),
                ),
                title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: spotifyWhite, fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: Text('Playlist',
                    style: TextStyle(color: spotifyLightGrey.withOpacity(0.7), fontSize: 12)),
              )),
        ],
        if (matchedFavorites.isNotEmpty) ...[
          _sectionHeader('Songs'),
          ...matchedFavorites.map((f) {
            final imgUrl = f.thumbnails.isNotEmpty ? f.thumbnails.last.url : '';
            return ListTile(
              onTap: () => ref.read(audioHandlerProvider).playVideo(f),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 48, height: 48,
                  child: imgUrl.isNotEmpty
                      ? CachedNetworkImage(imageUrl: imgUrl, fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(Icons.music_note, color: spotifyLightGrey))
                      : const Icon(Icons.music_note, color: spotifyLightGrey),
                ),
              ),
              title: Text(f.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: spotifyWhite, fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: Text(f.displayArtist,
                  style: TextStyle(color: spotifyLightGrey.withOpacity(0.7), fontSize: 12)),
            );
          }),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: spotifyWhite)),
    );
  }
}
