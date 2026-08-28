import 'package:muzo/screens/spotify_search_screen.dart';
import 'package:muzo/widgets/fade_indexed_stack.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muzo/providers/navigation_provider.dart';
import 'package:muzo/screens/spotify_library_screen.dart';
import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/models/user_data.dart';
import 'package:muzo/services/storage_service.dart';
import 'package:muzo/services/update_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:muzo/utils/page_routes.dart';
import 'package:muzo/screens/playlist_details_screen.dart';
import 'package:muzo/screens/settings_screen.dart';
import 'package:muzo/providers/player_provider.dart';
import 'package:muzo/widgets/quick_picks_section.dart';
import 'package:muzo/widgets/top_on_muzo_section.dart';
import 'package:muzo/providers/explore_provider.dart';
import 'package:muzo/services/navigator_key.dart';
import 'package:muzo/l10n/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storage = ref.read(storageServiceProvider);
      storage.refreshAll(silent: true);
      storage.fetchAndCacheUserAvatar();
      UpdateService().checkForUpdates(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: FadeIndexedStack(
          index: selectedIndex,
          children: [
            _buildHomeTab(context, ref),
            const SpotifySearchScreen(),
            const SpotifyLibraryScreen(),
            const SettingsScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: Theme.of(context).colorScheme.onSurface,
        backgroundColor: (Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).cardColor
            : Colors.white),
        onRefresh: () async {
          ref.invalidate(topOnMuzoProvider);
          await ref.read(storageServiceProvider).refreshAll();
        },
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader(context, ref)),

            // Liked Songs
            _buildLikedSongsSection(context, ref),

            // Quick Picks
            const SliverToBoxAdapter(child: QuickPicksSection()),

            // Top on Muzo (Trending)
            const SliverToBoxAdapter(child: TopOnMuzoSection()),

            // Recently Played
            _buildRecentlyPlayedSection(context, ref),

            // Your Playlists
            _buildYourPlaylistsSection(context, ref),

            // Bottom padding for mini player + nav bar
            const SliverPadding(padding: EdgeInsets.only(bottom: 140)),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageServiceProvider);
    final username = storage.username ?? 'User';
    final greeting = _greetingForHour(
      DateTime.now().hour,
      Localizations.localeOf(context).languageCode,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          // Logo
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              mainScaffoldKey.currentState?.openDrawer();
            },
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/hivefy_icon.png',
                  height: 34,
                  width: 34,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Greeting in front of the logo
          Flexible(
            child: Text.rich(
              TextSpan(
                text: '$greeting, ',
                children: [
                  TextSpan(
                    text: username,
                    style: const TextStyle(
                      color: Color(0xFF1DDA63),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const TextSpan(text: ' !'),
                ],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _greetingForHour(int hour, String lang) {
    const greetings = <String, List<String>>{
      'en': ['Good morning', 'Good afternoon', 'Good evening', 'Good night'],
      'fr': ['Bonjour', 'Bon après-midi', 'Bonsoir', 'Bonne nuit'],
      'es': ['Buenos días', 'Buenas tardes', 'Buenas noches', 'Buenas noches'],
      'de': ['Guten Morgen', 'Guten Nachmittag', 'Guten Abend', 'Gute Nacht'],
      'pt': ['Bom dia', 'Boa tarde', 'Boa noite', 'Boa noite'],
      'it': ['Buongiorno', 'Buon pomeriggio', 'Buonasera', 'Buonanotte'],
      'tr': ['Günaydın', 'İyi günler', 'İyi akşamlar', 'İyi geceler'],
      'hi': ['सुप्रभात', 'नमस्ते', 'शुभ संध्या', 'शुभ रात्रि'],
      'id': ['Selamat pagi', 'Selamat siang', 'Selamat malam', 'Selamat malam'],
      'vi': ['Chào buổi sáng', 'Chào buổi chiều', 'Chào buổi tối', 'Chúc ngủ ngon'],
      'ru': ['Доброе утро', 'Добрый день', 'Добрый вечер', 'Спокойной ночи'],
      'zh': ['早上好', '下午好', '晚上好', '晚安'],
      'ar': ['صباح الخير', 'مساء الخير', 'مساء الخير', 'تصبح على خير'],
    };
    final list = greetings[lang] ?? greetings['en']!;
    if (hour >= 5 && hour < 12) return list[0];
    if (hour >= 12 && hour < 18) return list[1];
    if (hour >= 18 && hour < 22) return list[2];
    return list[3];
  }

  // ── Liked Songs ────────────────────────────────────────────────────────────

  Widget _buildLikedSongsSection(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageServiceProvider);
    final l10n = AppLocalizations.of(context);
    return SliverToBoxAdapter(
      child: ValueListenableBuilder<List<MuzoItem>>(
        valueListenable: storage.favoritesListenable,
        builder: (context, favorites, _) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  SlidePageRoute(
                    page: const PlaylistDetailsScreen(
                      playlistName: 'Favorites',
                      isSystemPlaylist: true,
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/spotify/liked_songs.png',
                            fit: BoxFit.cover,
                          ),
                          Center(
                            child: Image.asset(
                              'assets/spotify/icon_heart_white.png',
                              width: 20,
                              height: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.likedSongs,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Image.asset('assets/spotify/icon_pin.png'),
                            const SizedBox(width: 5),
                            Text(
                              l10n.playlistCount(favorites.length),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xff777777),
                              ),
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
        },
      ),
    );
  }

  // ── Section header ─────────────────────────────────────────────────────────

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: -0.3,
            ),
      ),
    );
  }

  // ── Horizontal music card ──────────────────────────────────────────────────

  /// A square-ish card (width ~130) with a thumbnail and a single-line title.
  Widget _buildMusicCard({
    required BuildContext context,
    required String title,
    required String? imageUrl,
    required VoidCallback onTap,
  }) {
    const double cardWidth = 152;
    const double borderRadius = 8.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _placeholderTile(context),
                        )
                      : _placeholderTile(context),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderTile(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        FluentIcons.music_note_2_24_filled,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  // ── Recently Played ────────────────────────────────────────────────────────

  Widget _buildRecentlyPlayedSection(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageServiceProvider);
    final l10n = AppLocalizations.of(context);

    return SliverToBoxAdapter(
      child: ValueListenableBuilder<List<MuzoItem>>(
        valueListenable: storage.historyListenable,
        builder: (context, history, _) {
          // Deduplicate and filter to square-thumbnail items only
          final uniqueItems = <String, MuzoItem>{};
          for (final item in history) {
            if (item.videoId == null) continue;
            if (uniqueItems.containsKey(item.videoId)) continue;
            final thumb = item.thumbnails.lastOrNull;
            if (thumb == null) continue;
            bool isSquare = true;
            if (thumb.width > 0 && thumb.height > 0) {
              if (thumb.width != thumb.height) isSquare = false;
            } else {
              if (thumb.url.contains('i.ytimg.com')) isSquare = false;
            }
            if (isSquare) uniqueItems[item.videoId!] = item;
          }

          if (uniqueItems.isEmpty) return const SizedBox.shrink();

          final items = uniqueItems.values.toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(context, l10n.recentlyPlayed),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final imageUrl = item.thumbnails.lastOrNull?.url;
                    return Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: _buildMusicCard(
                        context: context,
                        title: item.title,
                        imageUrl: imageUrl,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref.read(audioHandlerProvider).playVideo(item);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Your Playlists ─────────────────────────────────────────────────────────

  Widget _buildYourPlaylistsSection(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageServiceProvider);
    final l10n = AppLocalizations.of(context);
    return SliverToBoxAdapter(
      child: ValueListenableBuilder<List<Playlist>>(
        valueListenable: storage.playlistsListenable,
        builder: (context, playlists, _) {
          if (playlists.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(context, l10n.yourPlaylists),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    final firstSong = playlist.songs.isNotEmpty
                        ? playlist.songs.first
                        : null;
                    final imageUrl =
                        firstSong?.thumbnails.isNotEmpty == true
                            ? firstSong!.thumbnails.last.url
                            : null;
                    return Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: _buildMusicCard(
                        context: context,
                        title: playlist.name,
                        imageUrl: imageUrl,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            SlidePageRoute(
                              page: PlaylistDetailsScreen(
                                  playlistName: playlist.name),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
