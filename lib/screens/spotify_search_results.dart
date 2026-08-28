import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/providers/player_provider.dart';
import 'package:muzo/providers/search_provider.dart';
import 'package:muzo/screens/album_screen.dart';
import 'package:muzo/screens/artist_screen.dart';
import 'package:muzo/screens/channel_screen.dart';
import 'package:muzo/screens/playlist_screen.dart';
import 'package:muzo/services/storage_service.dart';
import 'package:muzo/utils/page_routes.dart';
import 'package:muzo/l10n/app_localizations.dart';
import 'package:muzo/widgets/spotify_chips.dart';
import 'package:muzo/widgets/spotify_search_bar.dart';

class SpotifySearchResultsScreen extends ConsumerStatefulWidget {
  const SpotifySearchResultsScreen({super.key});

  @override
  ConsumerState<SpotifySearchResultsScreen> createState() =>
      _SpotifySearchResultsScreenState();
}

class _SpotifySearchResultsScreenState
    extends ConsumerState<SpotifySearchResultsScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
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

  void _submit(String q) {
    final query = q.trim();
    if (query.isEmpty) return;
    _controller.text = query;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    ref.read(storageServiceProvider).addSearchQuery(query);
    ref.read(searchQueryProvider.notifier).state = query;
    setState(() => _query = query);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final l10n = AppLocalizations.of(context);
    final history = _query.isEmpty ? storage.getSearchHistory() : const <String>[];
    final results = _query.isEmpty ? null : ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: spotifyBlack,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SpotifySearchBar(
                        controller: _controller,
                        autofocus: true,
                        onChanged: _onChanged,
                        onSubmitted: _submit,
                        hintText: l10n.search,
                        height: 42,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        l10n.cancel,
                        style: const TextStyle(color: spotifyWhite, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
              if (_query.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 15, bottom: 20),
                  child: Text(
                    l10n.recentSearches,
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      color: spotifyWhite,
                      fontSize: 17,
                    ),
                  ),
                ),
                if (history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      l10n.noRecentSearches,
                      style: const TextStyle(
                        color: spotifyLightGrey,
                        fontSize: 14,
                      ),
                    ),
                  )
                else
                  for (final q in history)
                    SpotifySongChip(
                      imageUrl: '',
                      songTitle: q,
                      singerName: l10n.search,
                      size: 47,
                      isDeletable: true,
                      onTap: () => _submit(q),
                      onDelete: () {
                        storage.clearSearchHistory();
                        setState(() {});
                      },
                    ),
              ] else ...[
                _buildResults(results),
              ],
              const SizedBox(height: 130),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(AsyncValue<List<MuzoItem>>? resultsAsync) {
    if (resultsAsync == null) return const SizedBox.shrink();
    return resultsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: spotifyWhite, strokeWidth: 2),
        ),
      ),
      error: (e, st) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            AppLocalizations.of(context).errorText('$e'),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      data: (results) {
        if (results.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                AppLocalizations.of(context).noResults,
                style: const TextStyle(
                  color: spotifyLightGrey,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }
        return Column(
          children: results.map((r) {
            final type = r.resultType.toLowerCase();
            final img = r.thumbnails.isNotEmpty ? r.thumbnails.last.url : '';
            final bId = r.browseId;
            final nav = Navigator.of(context);
            switch (type) {
              case 'artist':
                return SpotifyArtistChip(
                  imageUrl: img,
                  name: r.title,
                  radius: 23,
                  onTap: (bId != null && bId.isNotEmpty)
                      ? () => nav.push(
                            SlidePageRoute(
                              page: ArtistScreen(
                                browseId: bId,
                                artistName: r.title,
                                thumbnailUrl: img,
                              ),
                            ),
                          )
                      : null,
                );
              case 'album':
                return SpotifyAlbumChip(
                  imageUrl: img,
                  albumName: r.title,
                  artistName: r.displayArtist,
                  size: 47,
                  onTap: (bId != null && bId.isNotEmpty)
                      ? () => nav.push(
                            SlidePageRoute(
                              page: AlbumScreen(
                                albumId: bId,
                                albumName: r.title,
                                thumbnailUrl: img,
                              ),
                            ),
                          )
                      : null,
                );
              case 'playlist':
                return SpotifyAlbumChip(
                  imageUrl: img,
                  albumName: r.title,
                  artistName: AppLocalizations.of(context).playlistType,
                  size: 47,
                  onTap: (bId != null && bId.isNotEmpty)
                      ? () => nav.push(
                            SlidePageRoute(
                              page: PlaylistScreen(
                                playlistId: bId,
                                title: r.title,
                                thumbnailUrl: img,
                              ),
                            ),
                          )
                      : null,
                );
              case 'channel':
                return SpotifyArtistChip(
                  imageUrl: img,
                  name: r.title,
                  radius: 23,
                  onTap: (bId != null && bId.isNotEmpty)
                      ? () => nav.push(
                            SlidePageRoute(
                              page: ChannelScreen(
                                channelId: bId,
                                title: r.title,
                                thumbnailUrl: img,
                                subscriberCount: r.subscriberCount,
                                videoCount: r.videoCount,
                                description: r.description,
                              ),
                            ),
                          )
                      : null,
                );
              default:
                return SpotifySongChip(
                  imageUrl: img,
                  songTitle: r.title,
                  singerName: r.displayArtist,
                  size: 47,
                  videoId: r.videoId,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // Queue every result and start at this one so songs keep
                    // chaining after it finishes.
                    final idx = results.indexWhere((x) => identical(x, r));
                    ref
                        .read(audioHandlerProvider)
                        .playAll(results, startIndex: idx >= 0 ? idx : 0);
                  },
                );
            }
          }).toList(),
        );
      },
    );
  }
}
