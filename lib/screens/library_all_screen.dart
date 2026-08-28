import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muzo/providers/player_provider.dart';
import 'package:muzo/screens/artist_screen.dart';
import 'package:muzo/screens/channel_screen.dart';
import 'package:muzo/screens/playlist_details_screen.dart';
import 'package:muzo/services/storage_service.dart';
import 'package:muzo/utils/page_routes.dart';
import 'package:muzo/l10n/app_localizations.dart';
import 'package:muzo/widgets/spotify_chips.dart';
import 'package:muzo/widgets/spotify_back_button.dart';
import 'package:muzo/widgets/spotify_search_bar.dart';

class LibraryAllScreen extends ConsumerStatefulWidget {
  const LibraryAllScreen({super.key});

  @override
  ConsumerState<LibraryAllScreen> createState() => _LibraryAllScreenState();
}

class _LibraryAllScreenState extends ConsumerState<LibraryAllScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_AllEntry> _buildEntries(StorageService storage, AppLocalizations l10n) {
    final entries = <_AllEntry>[];

    // Liked Songs
    final favorites = storage.getFavorites();
    entries.add(_AllEntry(
      key: 'liked_songs',
      title: 'Liked Songs',
      subtitle: '${favorites.length} songs',
      imageUrl: '',
      kind: _AllKind.liked,
      onTap: () => Navigator.push(
        context,
        SlidePageRoute(
            page: const PlaylistDetailsScreen(
                playlistName: 'Favorites', isSystemPlaylist: true)),
      ),
    ));

    // Folders
    for (final folder in storage.getFolders()) {
      final name = folder['name'] as String;
      final playlistNames = List<String>.from(folder['playlists'] ?? []);
      entries.add(_AllEntry(
        key: 'folder_$name',
        title: name,
        subtitle: '${playlistNames.length} playlists',
        imageUrl: '',
        kind: _AllKind.folder,
      ));
    }

    // Playlists
    for (final name in storage.getPlaylistNames()) {
      final songs = storage.getPlaylistSongs(name);
      final img = songs.isNotEmpty && songs.first.thumbnails.isNotEmpty
          ? songs.first.thumbnails.last.url
          : '';
      entries.add(_AllEntry(
        key: 'playlist_$name',
        title: name,
        subtitle: 'Playlist • ${songs.length} songs',
        imageUrl: img,
        kind: _AllKind.playlist,
        onTap: () => Navigator.push(
            context, SlidePageRoute(page: PlaylistDetailsScreen(playlistName: name))),
      ));
    }

    // Artists (from history)
    final history = storage.getHistory();
    final processedArtists = <String>{};
    for (final song in history) {
      if (song.artists == null) continue;
      for (final artist in song.artists!) {
        final artistName = artist.name.trim();
        if (artistName.isEmpty || artistName == 'Unknown') continue;
        if (artistName.contains(',') ||
            artistName.contains('&') ||
            artistName.toLowerCase().contains(' feat ') ||
            artistName.toLowerCase().contains(' ft ')) {
          continue;
        }
        if (processedArtists.contains(artistName)) continue;
        processedArtists.add(artistName);
        final img = song.thumbnails.isNotEmpty ? song.thumbnails.last.url : '';
        final id = (artist.id != null && artist.id!.isNotEmpty) ? artist.id! : '';
        entries.add(_AllEntry(
          key: 'artist_$artistName',
          title: artistName,
          subtitle: 'Artist',
          imageUrl: img,
          kind: _AllKind.artist,
          onTap: id.isNotEmpty
              ? () => Navigator.push(context,
                  SlidePageRoute(page: ArtistScreen(browseId: id, artistName: artistName, thumbnailUrl: img)))
              : null,
        ));
      }
    }

    // Albums (from history)
    final seenAlbums = <String>{};
    for (final song in history) {
      final albumName = song.album?.name.trim() ?? '';
      if (albumName.isEmpty || albumName == 'Unknown') continue;
      if (seenAlbums.contains(albumName)) continue;
      seenAlbums.add(albumName);
      final img = song.thumbnails.isNotEmpty ? song.thumbnails.last.url : '';
      entries.add(_AllEntry(
        key: 'album_$albumName',
        title: albumName,
        subtitle: 'Album • ${song.displayArtist}',
        imageUrl: img,
        kind: _AllKind.album,
        onTap: () {
          HapticFeedback.lightImpact();
          ref.read(audioHandlerProvider).playVideo(song);
        },
      ));
    }

    // Podcasts
    for (final ch in storage.getSubscriptions()) {
      final img = ch.avatar ?? '';
      entries.add(_AllEntry(
        key: 'podcast_${ch.name}',
        title: ch.name,
        subtitle: 'Podcast',
        imageUrl: img,
        kind: _AllKind.podcast,
        onTap: () => Navigator.push(
          context,
          SlidePageRoute(
            page: ChannelScreen(
              channelId: ch.channelId ?? '',
              title: ch.name,
              thumbnailUrl: img,
            ),
          ),
        ),
      ));
    }

    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: spotifyBlack,
      body: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            storage.playlistsListenable,
            storage.favoritesListenable,
            storage.historyListenable,
            storage.downloadsListenable,
            storage.subscriptionsListenable,
          ]),
          builder: (context, _) {
            final all = _buildEntries(storage, l10n);
            final filtered = _searchQuery.isEmpty
                ? all
                : all
                    .where((e) =>
                        e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        e.subtitle.toLowerCase().contains(_searchQuery.toLowerCase()))
                    .toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: Row(
                      children: [
                        const SpotifyBackButton(),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'All',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: spotifyWhite,
                            ),
                          ),
                        ),
                        if (all.isNotEmpty)
                          Text(
                            '${all.length}',
                            style: const TextStyle(
                              color: spotifyLightGrey,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SpotifySearchBar(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      hintText: l10n.search,
                      height: 40,
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'Nothing in your library yet',
                        style: TextStyle(color: spotifyLightGrey, fontSize: 16),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildTile(filtered[index]),
                        childCount: filtered.length,
                      ),
                    ),
                  ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 130)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTile(_AllEntry e) {
    Widget leading;
    if (e.kind == _AllKind.liked) {
      leading = SizedBox(
        width: 52,
        height: 52,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/spotify/liked_songs.png', fit: BoxFit.cover),
              Center(
                child: Image.asset('assets/spotify/icon_heart_white.png',
                    width: 20, height: 20),
              ),
            ],
          ),
        ),
      );
    } else if (e.kind == _AllKind.folder) {
      leading = Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: spotifyDarkGrey,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.folder, color: Color(0xFF1DDA63), size: 26),
      );
    } else {
      final isArtist = e.kind == _AllKind.artist;
      leading = SizedBox(
        width: 52,
        height: 52,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isArtist ? 26 : 6),
          child: e.imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: e.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _placeholder(e.kind),
                )
              : _placeholder(e.kind),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: e.onTap,
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      color: spotifyWhite,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    e.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: spotifyLightGrey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(_AllKind kind) {
    final icon = switch (kind) {
      _AllKind.artist => Icons.person,
      _AllKind.podcast => Icons.podcasts,
      _AllKind.playlist => Icons.playlist_play,
      _AllKind.album => Icons.album,
      _ => Icons.music_note,
    };
    return Container(
      color: spotifyDarkGrey,
      child: Icon(icon, color: spotifyLightGrey, size: 26),
    );
  }
}

enum _AllKind { liked, folder, playlist, artist, album, podcast }

class _AllEntry {
  const _AllEntry({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.kind,
    this.onTap,
  });
  final String key;
  final String title;
  final String subtitle;
  final String imageUrl;
  final _AllKind kind;
  final VoidCallback? onTap;
}
