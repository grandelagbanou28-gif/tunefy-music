import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muzo/providers/player_provider.dart';
import 'package:muzo/screens/playlist_details_screen.dart';
import 'package:muzo/screens/artist_screen.dart';
import 'package:muzo/screens/profile_screen.dart';
import 'package:muzo/services/storage_service.dart';
import 'package:muzo/utils/page_routes.dart';
import 'package:muzo/l10n/app_localizations.dart';
import 'package:muzo/widgets/spotify_chips.dart';
import 'package:muzo/widgets/glass_snackbar.dart';
import 'package:muzo/screens/library_search_screen.dart';
import 'package:muzo/screens/library_playlists_screen.dart';
import 'package:muzo/screens/library_artists_screen.dart';
import 'package:muzo/screens/library_albums_screen.dart';
import 'package:muzo/screens/library_podcasts_screen.dart';
import 'package:muzo/screens/library_songs_screen.dart';

class SpotifyLibraryScreen extends ConsumerStatefulWidget {
  const SpotifyLibraryScreen({super.key});

  @override
  ConsumerState<SpotifyLibraryScreen> createState() =>
      _SpotifyLibraryScreenState();
}

class _SpotifyLibraryScreenState extends ConsumerState<SpotifyLibraryScreen> {
  bool _isGrid = false;
  String _sortLabel = 'All';

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
            final items = _getItems(storage, l10n);
            final isEmpty = items.length <= 1;
            return CustomScrollView(
              slivers: [
                // ─── Header ───
                SliverToBoxAdapter(
                  child: _buildMainHeader(storage, l10n),
                ),

                // ─── Filter chips ───
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      children: [
                        _buildChip('Songs', () => _openPage(const LibrarySongsScreen())),
                        const SizedBox(width: 8),
                        _buildChip(l10n.albumsFilter, () => _openPage(const LibraryAlbumsScreen())),
                        const SizedBox(width: 8),
                        _buildChip(l10n.artistsFilter, () => _openPage(const LibraryArtistsScreen())),
                        const SizedBox(width: 8),
                        _buildChip(l10n.playlistsFilter, () => _openPage(const LibraryPlaylistsScreen())),
                        const SizedBox(width: 8),
                        _buildChip(l10n.podcastsLabel, () => _openPage(const LibraryPodcastsScreen())),
                      ],
                    ),
                  ),
                ),

                // ─── Sort + grid toggle row ───
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showSortSheet(context, l10n),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.swap_vert, color: spotifyLightGrey, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  _sortLabel,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: spotifyLightGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _isGrid = !_isGrid),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              _isGrid ? Icons.grid_view : Icons.grid_view_outlined,
                              color: spotifyLightGrey,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Content ───
                if (isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyState())
                else
                  _isGrid
                      ? _buildGridItems(context, storage, items)
                      : _buildListItems(context, storage, items),

                const SliverPadding(padding: EdgeInsets.only(bottom: 200)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── Main header ───
  Widget _buildMainHeader(StorageService storage, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 25, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
                context, SlidePageRoute(page: const ProfileScreen())),
            child: _buildAvatar(storage),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.yourLibrary,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: spotifyWhite,
              ),
            ),
          ),
          GestureDetector(
            onTap: _showCreateMenu,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.add, color: spotifyWhite, size: 28),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LibrarySearchScreen(),
                ),
              );
            },
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.search, color: spotifyWhite, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Create menu (+) ───
  void _showCreateMenu() {
    final l10n = AppLocalizations.of(context);
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: spotifyDarkGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: spotifyWhite.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Create',
                    style: const TextStyle(
                      color: spotifyWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3A3A3A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: spotifyWhite,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, thickness: 0.5, color: Color(0xFF3A3A3A)),
            _createTile(
              icon: Icons.queue_music,
              iconColor: spotifyBlack,
              tileColor: const Color(0xFF1DDA63),
              label: l10n.createPlaylist,
              onTap: () {
                Navigator.pop(ctx);
                _showCreatePlaylistDialog(context);
              },
            ),
            const Divider(height: 1, thickness: 0.5, color: Color(0xFF3A3A3A)),
            _createTile(
              icon: Icons.create_new_folder_outlined,
              iconColor: spotifyWhite,
              tileColor: const Color(0xFF2E77D0),
              label: 'Create folder',
              onTap: () {
                Navigator.pop(ctx);
                _showCreateFolderDialog(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _createTile({
    required IconData icon,
    required Color iconColor,
    required Color tileColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: tileColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: spotifyWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Spotify-style dark dialog asking for a playlist/folder name.
  /// Returns the trimmed name, or null when cancelled.
  Future<String?> _showSpotifyTextDialog({
    required String title,
    required String hint,
    String? initialText,
    String confirmLabel = 'Create',
  }) {
    final controller = TextEditingController(text: initialText);
    return showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF282828),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: spotifyWhite,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: spotifyWhite, fontSize: 15),
                cursorColor: spotifyWhite,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: spotifyLightGrey),
                  filled: true,
                  fillColor: const Color(0xFF3E3E3E),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (value) {
                  final name = value.trim();
                  if (name.isNotEmpty) Navigator.pop(ctx, name);
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: spotifyWhite, fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () {
                      final name = controller.text.trim();
                      if (name.isNotEmpty) Navigator.pop(ctx, name);
                    },
                    child: Text(
                      confirmLabel,
                      style: const TextStyle(
                        color: Color(0xFF1DDA63),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final name = await _showSpotifyTextDialog(
      title: l10n.createPlaylist,
      hint: l10n.playlistNameHint,
      confirmLabel: l10n.createBtn,
    );
    if (name == null || name.isEmpty) return;
    ref.read(storageServiceProvider).createPlaylist(name);
    setState(() {});
  }

  Future<void> _showCreateFolderDialog(BuildContext context) async {
    final name = await _showSpotifyTextDialog(
      title: 'Create folder',
      hint: 'Folder name',
      confirmLabel: 'Create',
    );
    if (name == null || name.isEmpty) return;
    ref.read(storageServiceProvider).createFolder(name);
    setState(() {});
  }

  Future<void> _showRenameFolderDialog(BuildContext context, String oldName) async {
    final name = await _showSpotifyTextDialog(
      title: 'Rename folder',
      hint: 'Folder name',
      initialText: oldName,
      confirmLabel: 'Save',
    );
    if (name == null || name.isEmpty || name == oldName) return;
    ref.read(storageServiceProvider).renameFolder(oldName, name);
    setState(() {});
  }

  // ─── Chips ───
  Widget _buildChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 34,
        decoration: BoxDecoration(
          color: spotifyDarkGrey,
          border: Border.all(color: spotifyLightGrey),
          borderRadius: BorderRadius.circular(17),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: spotifyWhite,
          ),
        ),
      ),
    );
  }

  void _openPage(Widget page) {
    HapticFeedback.lightImpact();
    Navigator.push(context, SlidePageRoute(page: page));
  }

  // ─── Sort sheet ───
  void _showSortSheet(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: spotifyDarkGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: spotifyWhite.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                l10n.sortBy,
                style: const TextStyle(
                  color: spotifyWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _sortTile(ctx, 'All'),
            _sortTile(ctx, l10n.recentlyPlayedSort),
            _sortTile(ctx, l10n.alphabetical),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sortTile(BuildContext ctx, String label) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: spotifyWhite, fontSize: 15)),
      trailing: _sortLabel == label
          ? const Icon(Icons.check, color: Color(0xFF1DDA63), size: 20)
          : null,
      onTap: () {
        setState(() => _sortLabel = label);
        Navigator.pop(ctx);
      },
    );
  }

  // ─── Avatar ───
  Widget _buildAvatar(StorageService storage) {
    return ValueListenableBuilder(
      valueListenable: storage.userAvatarListenable,
      builder: (context, box, _) {
        final localPhoto = storage.profilePhotoPath;
        final localFile = (localPhoto != null && File(localPhoto).existsSync())
            ? File(localPhoto)
            : null;
        final avatarUrl = storage.avatarUrl;
        final cachedSvg = storage.getUserAvatar();
        final isSvg = avatarUrl == null ||
            avatarUrl.contains('.svg') ||
            avatarUrl.contains('dicebear');
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: spotifyWhite.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: CircleAvatar(
            radius: 17,
            backgroundColor: spotifyDarkGrey,
            child: ClipOval(
              child: localFile != null
                  ? Image.file(localFile, height: 34, width: 34,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                          'assets/covers/app_icon.png',
                          height: 34, width: 34, fit: BoxFit.cover))
                  : isSvg && cachedSvg != null
                  ? SvgPicture.string(cachedSvg, height: 34, width: 34, fit: BoxFit.cover)
                  : avatarUrl != null && !isSvg
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl, height: 34, width: 34, fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Image.asset('assets/covers/app_icon.png',
                                  height: 34, width: 34, fit: BoxFit.cover),
                        )
                      : Image.asset('assets/covers/app_icon.png',
                          height: 34, width: 34, fit: BoxFit.cover),
            ),
          ),
        );
      },
    );
  }

  // ─── Build data ───
  List<_LibItem> _getItems(StorageService storage, AppLocalizations l10n) {
    final items = <_LibItem>[];

    // Liked Songs (always first)
    items.add(_LibItem(
      id: 'liked_songs',
      type: _LibType.likedSongs,
      title: 'Liked Songs',
      subtitle: 'Playlist • ${storage.getFavorites().length} songs',
      imageUrl: '',
    ));

    // Folders
    final folders = storage.getFolders();
    for (final folder in folders) {
      final name = folder['name'] as String;
      final playlistNames = List<String>.from(folder['playlists'] ?? []);
      items.add(_LibItem(
        id: 'folder_$name',
        type: _LibType.folder,
        title: name,
        subtitle: '${playlistNames.length} playlists',
        imageUrl: '',
      ));
    }

    for (final name in storage.getPlaylistNames()) {
      final songs = storage.getPlaylistSongs(name);
      final img = songs.isNotEmpty && songs.first.thumbnails.isNotEmpty
          ? songs.first.thumbnails.last.url
          : '';
      items.add(_LibItem(
        id: 'playlist_$name',
        type: _LibType.playlist,
        title: name,
        subtitle: 'Playlist • ${songs.length} songs',
        imageUrl: img,
        onTap: () => Navigator.push(
            context, SlidePageRoute(page: PlaylistDetailsScreen(playlistName: name))),
      ));
    }

    final history = storage.getHistory();

    final processed = <String>{};
    var count = 0;
    for (final song in history) {
      if (song.artists == null) continue;
      for (final artist in song.artists!) {
        final name = artist.name.trim();
        if (name.isEmpty || name == 'Unknown') continue;
        if (name.contains(',') || name.contains('&') ||
            name.toLowerCase().contains(' feat ') || name.toLowerCase().contains(' ft ')) {
          continue;
        }
        if (processed.contains(name)) continue;
        processed.add(name);
        count++;
        if (count > 20) break;
        final img = song.thumbnails.isNotEmpty ? song.thumbnails.last.url : '';
        final id = (artist.id != null && artist.id!.isNotEmpty) ? artist.id! : '';
        items.add(_LibItem(
          id: 'artist_$name',
          type: _LibType.artist,
          title: name,
          subtitle: 'Artist',
          imageUrl: img,
          isCircle: true,
          onTap: id.isNotEmpty
              ? () => Navigator.push(context,
                  SlidePageRoute(page: ArtistScreen(browseId: id, artistName: name, thumbnailUrl: img)))
              : null,        ));
      }
      if (count > 20) break;
    }

    final seen = <String>{};
    for (final song in history) {
      final albumName = song.album?.name.trim() ?? '';
      if (albumName.isEmpty || albumName == 'Unknown') continue;
      if (seen.contains(albumName)) continue;
      seen.add(albumName);
      final img = song.thumbnails.isNotEmpty ? song.thumbnails.last.url : '';
      items.add(_LibItem(
        id: 'album_$albumName',
        type: _LibType.album,
        title: albumName,
        subtitle: 'Album • ${song.displayArtist}',
        imageUrl: img,
        onTap: () {
          HapticFeedback.lightImpact();
          ref.read(audioHandlerProvider).playVideo(song);
        },
      ));
      if (seen.length >= 15) break;
    }

    final subs = storage.getSubscriptions();
    for (final ch in subs) {
      final img = ch.avatar ?? '';
      items.add(_LibItem(
        id: 'podcast_${ch.name}',
        type: _LibType.podcast,
        title: ch.name,
        subtitle: 'Podcast',
        imageUrl: img,
      ));
    }

    // Sort
    List<_LibItem> ordered;
    if (_sortLabel == l10n.alphabetical) {
      final liked = items.first;
      final rest = items.sublist(1);
      rest.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      ordered = [liked, ...rest];
    } else if (_sortLabel == l10n.recentlyPlayedSort) {
      final liked = items.first;
      final rest = items.sublist(1);
      final recents = <_LibItem>[];
      final others = <_LibItem>[];
      for (final item in rest) {
        if (item.type == _LibType.artist || item.type == _LibType.album) {
          recents.add(item);
        } else {
          others.add(item);
        }
      }
      ordered = [liked, ...recents, ...others];
    } else {
      ordered = items;
    }

    return _applyPinned(storage, ordered);
  }

  List<_LibItem> _applyPinned(StorageService storage, List<_LibItem> ordered) {
    final pinned = storage.getPinnedItems();
    if (pinned.isEmpty) return ordered;
    final pinnedItems = <_LibItem>[];
    final unpinnedItems = <_LibItem>[];
    for (final item in ordered) {
      if (item.id == 'liked_songs') {
        unpinnedItems.add(item);
        continue;
      }
      if (pinned.contains(item.id)) {
        pinnedItems.add(item);
      } else {
        unpinnedItems.add(item);
      }
    }
    return [unpinnedItems.first, ...pinnedItems, ...unpinnedItems.sublist(1)];
  }

  // ─── Empty state ───
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 56, 32, 0),
      child: Column(
        children: [
          const Icon(Icons.music_note, size: 56, color: spotifyWhite),
          const SizedBox(height: 18),
          const Text(
            'Your library is empty',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: spotifyWhite,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Playlists, albums and artists you like will appear here.\nCreate a playlist to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(color: spotifyLightGrey, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: _showCreateMenu,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Create playlist',
                style: TextStyle(
                  color: spotifyBlack,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── List view ───
  SliverList _buildListItems(
      BuildContext context, StorageService storage, List<_LibItem> items) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildListTile(items[index], storage),
        childCount: items.length,
      ),
    );
  }

  // ─── Grid view ───
  SliverGrid _buildGridItems(
      BuildContext context, StorageService storage, List<_LibItem> items) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildGridTile(items[index], storage),
        childCount: items.length,
      ),
    );
  }

  // ─── List tile ───
  Widget _buildListTile(_LibItem item, StorageService storage) {
    final pinned = storage.isPinned(item.id);
    if (item.type == _LibType.likedSongs) return _buildLikedSongsTile(item);
    if (item.type == _LibType.folder) return _buildFolderTile(item);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: item.onTap,
      onLongPress: () => _showContextMenu(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(item.isCircle ? 28 : 6),
                child: item.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _placeholder(item),
                      )
                    : _placeholder(item),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15, color: spotifyWhite, fontWeight: FontWeight.w500)),
                      ),
                      if (pinned) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.push_pin, size: 13, color: spotifyLightGrey),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (item.type == _LibType.playlist) ...[
                        Container(
                          width: 14, height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xffC4C4C4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          alignment: Alignment.center,
                          child: const Text('E',
                              style: TextStyle(fontSize: 8, color: spotifyBlack, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Expanded(
                        child: Text(item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: spotifyLightGrey)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Liked Songs tile ───
  Widget _buildLikedSongsTile(_LibItem item) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _showContextMenu(item),
      onTap: () => Navigator.push(
        context,
        SlidePageRoute(
            page: const PlaylistDetailsScreen(playlistName: 'Favorites', isSystemPlaylist: true)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 56, height: 56,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset('assets/spotify/liked_songs.png', fit: BoxFit.cover),
                    Center(
                      child: Image.asset('assets/spotify/icon_heart_white.png', width: 22, height: 22),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Liked Songs',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15, color: spotifyWhite, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Image.asset('assets/spotify/icon_pin.png', width: 12, height: 12),
                      const SizedBox(width: 5),
                      Text(item.subtitle,
                          style: const TextStyle(fontSize: 13, color: spotifyLightGrey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Folder tile ───
  Widget _buildFolderTile(_LibItem item) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _showFolderContextMenu(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: spotifyDarkGrey,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.folder, color: Color(0xFF1DDA63), size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, color: spotifyWhite, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text(item.subtitle,
                      style: const TextStyle(fontSize: 13, color: spotifyLightGrey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Grid tile ───
  Widget _buildGridTile(_LibItem item, StorageService storage) {
    final pinned = storage.isPinned(item.id);
    if (item.type == _LibType.likedSongs) return _buildLikedSongsGridTile(item);
    if (item.type == _LibType.folder) return _buildFolderGridTile(item);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: item.onTap,
      onLongPress: () => _showContextMenu(item),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(item.isCircle ? 44 : 8),
                child: SizedBox.expand(
                  child: item.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl, fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _placeholder(item),
                        )
                      : _placeholder(item),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: spotifyWhite, fontWeight: FontWeight.w600)),
                ),
                if (pinned) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.push_pin, size: 11, color: spotifyLightGrey),
                ],
              ],
            ),
            if (item.subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: spotifyLightGrey)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLikedSongsGridTile(_LibItem item) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _showContextMenu(item),
      onTap: () => Navigator.push(
        context,
        SlidePageRoute(
            page: const PlaylistDetailsScreen(playlistName: 'Favorites', isSystemPlaylist: true)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox.expand(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset('assets/spotify/liked_songs.png', fit: BoxFit.cover),
                      Center(
                        child: Image.asset('assets/spotify/icon_heart_white.png', width: 28, height: 28),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text('Liked Songs',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13, color: spotifyWhite, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderGridTile(_LibItem item) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _showFolderContextMenu(item),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: spotifyDarkGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.folder, color: Color(0xFF1DDA63), size: 28),
              ),
            ),
            const SizedBox(height: 6),
            Text(item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, color: spotifyWhite, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ─── Placeholder ───
  Widget _placeholder(_LibItem item) {
    IconData icon;
    switch (item.type) {
      case _LibType.artist:
        icon = Icons.person;
        break;
      case _LibType.podcast:
        icon = Icons.podcasts;
        break;
      default:
        icon = Icons.music_note;
    }
    return Container(
      color: spotifyDarkGrey,
      child: Icon(icon, color: spotifyLightGrey, size: 28),
    );
  }

  // ─── Context menu (long press) ───
  void _showContextMenu(_LibItem item) {
    final storage = ref.read(storageServiceProvider);
    final isPinned = storage.isPinned(item.id);
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: spotifyDarkGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(item.isCircle ? 25 : 6),
                    child: SizedBox(
                      width: 50, height: 50,
                      child: item.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item.imageUrl, fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => _placeholder(item),
                            )
                          : _placeholder(item),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: spotifyWhite, fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: spotifyLightGrey, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            _menuTile(
              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              isPinned ? 'Unpin from top' : 'Pin to top',
              onTap: () {
                Navigator.pop(ctx);
                if (isPinned) {
                  storage.unpinItem(item.id);
                } else {
                  storage.pinItem(item.id);
                }
                setState(() {});
              },
            ),
            _menuTile(Icons.share, 'Share', onTap: () {
              Navigator.pop(ctx);
              Clipboard.setData(ClipboardData(text: item.title));
              showGlassSnackBar(context, '${item.title} shared');
            }),
            if (item.type == _LibType.playlist)
              _menuTile(Icons.delete_outline, 'Remove from Your Library',
                  isDestructive: true, onTap: () {
                Navigator.pop(ctx);
                storage.deletePlaylist(item.title);
                showGlassSnackBar(context, '${item.title} removed from Your Library');
                setState(() {});
              }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── Folder context menu ───
  void _showFolderContextMenu(_LibItem item) {
    final storage = ref.read(storageServiceProvider);
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: spotifyDarkGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: spotifyDarkGrey,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.folder, color: Color(0xFF1DDA63), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: spotifyWhite, fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            _menuTile(Icons.edit, 'Rename', onTap: () {
              Navigator.pop(ctx);
              _showRenameFolderDialog(context, item.title);
            }),
            _menuTile(Icons.delete_outline, 'Delete', isDestructive: true, onTap: () {
              Navigator.pop(ctx);
              storage.deleteFolder(item.title);
              showGlassSnackBar(context, '"${item.title}" folder deleted');
              setState(() {});
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(IconData icon, String label,
      {bool isDestructive = false, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : spotifyWhite, size: 22),
      title: Text(label,
          style: TextStyle(
            color: isDestructive ? Colors.red : spotifyWhite,
            fontSize: 15,
          )),
      onTap: onTap ?? () => Navigator.pop(context),
    );
  }
}

// ─── Data model ───
enum _LibType { likedSongs, folder, playlist, artist, album, podcast }

class _LibItem {
  const _LibItem({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle = '',
    this.imageUrl = '',
    this.isCircle = false,
    this.onTap,
  });
  final String id;
  final _LibType type;
  final String title;
  final String subtitle;
  final String imageUrl;
  final bool isCircle;
  final VoidCallback? onTap;
}
