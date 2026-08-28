import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muzo/l10n/app_localizations.dart';
import 'package:muzo/screens/spotify_code_scanner_screen.dart';
import 'package:muzo/screens/global_search_screen.dart';
import 'package:muzo/screens/category_screen.dart';
import 'package:muzo/services/navigator_key.dart';
import 'package:muzo/services/storage_service.dart';
import 'package:muzo/widgets/spotify_chips.dart';

/// Spotify-style Search page: a search bar and a user-editable "Browse All"
/// genre grid.
class SpotifySearchScreen extends ConsumerWidget {
  const SpotifySearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final storage = ref.watch(storageServiceProvider);
    final chosen = storage.chosenCategories.toSet();
    final ordered = [..._kBrowseCards]
      ..sort((a, b) {
        final ai = chosen.contains(a.title) ? 0 : 1;
        final bi = chosen.contains(b.title) ? 0 : 1;
        if (ai != bi) return ai - bi;
        return 0;
      });

    return Scaffold(
      backgroundColor: spotifyBlack,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // ─── Header ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Row(
                  children: [
                    Text(
                      l10n.search,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: spotifyWhite,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SpotifyCodeScannerScreen(),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: spotifyWhite,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Search bar ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GlobalSearchScreen(),
                      ),
                    );
                  },
                  child: Container(
                    height: 48,
                    decoration: const BoxDecoration(
                      color: spotifyWhite,
                      borderRadius: BorderRadius.all(Radius.circular(500)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: spotifyDarkGrey.withValues(alpha: 0.7), size: 22),
                        const SizedBox(width: 12),
                        Text(
                          'Artists, songs, or podcasts',
                          style: TextStyle(
                            color: spotifyDarkGrey.withValues(alpha: 0.55),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ─── Browse all (categories header) ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Text(
                  'Browse all',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: spotifyWhite,
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.6,
                ),
                delegate: SliverChildListDelegate(
                  ordered.map((c) => _buildCard(c, chosen.contains(c.title))).toList(),
                ),
              ),
            ),

            const SliverPadding(
              padding: EdgeInsets.only(bottom: 130),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(_BrowseCardData c, bool selected) {
    return _AssetCategoryCard(
      title: c.title,
      color: c.color,
      asset: c.asset,
      icon: c.icon,
      query: c.query,
      selected: selected,
      onTap: () {
        HapticFeedback.lightImpact();
        final navigator = navigatorKey.currentContext == null
            ? null
            : Navigator.of(navigatorKey.currentContext!);
        navigator?.push(
          MaterialPageRoute(
            builder: (_) => CategoryScreen(
              title: c.title,
              query: c.query,
              color: c.color,
              asset: c.asset,
              icon: c.icon,
              subs: c.subs,
            ),
          ),
        );
      },
    );
  }

  Future<void> _openEditSheet(BuildContext context, WidgetRef ref) async {
    final storage = ref.read(storageServiceProvider);
    final selected = storage.chosenCategories.toSet();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: spotifyBlack,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
    final ordered = [..._kBrowseCards]
            ..sort((a, b) {
              final ai = selected.contains(a.title) ? 0 : 1;
              final bi = selected.contains(b.title) ? 0 : 1;
              if (ai != bi) return ai - bi;
              return 0;
            });
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Choose your categories',
                            style: TextStyle(
                              color: spotifyWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            storage.setChosenCategories(selected.toList());
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              color: Color(0xFF1DDA63),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 360,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: ordered.length,
                      itemBuilder: (context, index) {
                        final c = ordered[index];
                        final isSelected = selected.contains(c.title);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (v) {
                            setSheetState(() {
                              if (v == true) {
                                selected.add(c.title);
                              } else {
                                selected.remove(c.title);
                              }
                            });
                          },
                          activeColor: const Color(0xFF1DDA63),
                          checkColor: spotifyBlack,
                          title: Text(
                            c.title,
                            style: TextStyle(
                              color: isSelected ? spotifyWhite : spotifyLightGrey,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
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
}

class _BrowseCardData {
  const _BrowseCardData({
    required this.title,
    required this.color,
    this.asset,
    this.icon,
    required this.query,
    this.subs = const [],
  });

  final String title;
  final Color color;
  final String? asset;
  final IconData? icon;
  final String query;
  final List<String> subs;
}

final List<_BrowseCardData> _kBrowseCards = [
  const _BrowseCardData(
    title: 'Music',
    color: Color(0xFFE13300),
    asset: 'assets/covers/music.jpg',
    query: 'music',
    subs: [
      'All Music',
      'New Music',
      'Trending',
      'Popular',
      'Top Songs',
      'Top Albums',
      'Top Artists',
      'Singles',
      'Albums',
      'Playlists',
      'Compilations',
      'Music Videos',
    ],
  ),
  const _BrowseCardData(
    title: 'Podcasts',
    color: Color(0xFF006450),
    asset: 'assets/covers/podcasts.jpg',
    query: 'podcast',
    subs: [
      'All Podcasts',
      'Trending Podcasts',
      'New Podcasts',
      'Popular Podcasts',
      'News',
      'True Crime',
      'Comedy',
      'Business',
      'Technology',
      'Education',
      'Sports',
      'Culture',
      'Music',
      'Society',
      'History',
      'Science',
      'Stories',
      'Interviews',
      'Religion & Spirituality',
    ],
  ),
  const _BrowseCardData(
    title: 'Amapiano',
    color: Color(0xFF8400E7),
    asset: 'assets/covers/amapiano.jpg',
    icon: Icons.piano,
    query: 'amapiano',
    subs: [
      'Amapiano Hits',
      'Private School Piano',
      'Log Drums',
      'Yanos Classics',
      'SA House',
      'Amapiano Mix',
      'Afro Piano',
      'Piano & Amapiano',
    ],
  ),
  const _BrowseCardData(
    title: 'Made For You',
    color: Color(0xFF1E3264),
    asset: 'assets/covers/madeforyou.jpg',
    query: 'chill mix',
    subs: [
      'Discover Weekly',
      'Release Radar',
      'Daily Mix',
      'Artist Mix',
      'Genre Mix',
      'Mood Mix',
      'Time Capsule',
      'Your Top Songs',
      'Your Favorites',
      'Recently Played',
      'Based on Your Listening',
      'Because You Like...',
    ],
  ),
  const _BrowseCardData(
    title: 'New Releases',
    color: Color(0xFFE8115B),
    asset: 'assets/covers/newreleases.jpg',
    icon: Icons.new_releases,
    query: 'new release',
    subs: [
      'New Songs',
      'New Albums',
      'New EPs',
      'New Singles',
      'New Artists',
      'New Music Videos',
      'This Week',
      'Today',
      'Upcoming Releases',
      'New Releases by Genre',
      'New Releases by Country',
    ],
  ),
  const _BrowseCardData(
    title: 'Pop',
    color: Color(0xFF148A08),
    asset: 'assets/covers/pop.jpg',
    query: 'pop',
    subs: [
      'Pop Hits',
      'New Pop',
      'Pop Classics',
      'Dance Pop',
      'Teen Pop',
      'Electropop',
      'Indie Pop',
      'K-Pop Pop',
      'Afro Pop',
      'French Pop',
      'US Pop',
      'UK Pop',
    ],
  ),
  const _BrowseCardData(
    title: 'Hip-Hop',
    color: Color(0xFFBA5D07),
    asset: 'assets/covers/hiphop.jpg',
    icon: Icons.mic,
    query: 'hip hop',
    subs: [
      'Hip-Hop Hits',
      'New Hip-Hop',
      'Trap',
      'Drill',
      'Boom Bap',
      'Conscious Hip-Hop',
      'Alternative Hip-Hop',
      'Underground',
      'Southern Hip-Hop',
      'East Coast',
      'West Coast',
      'French Hip-Hop',
      'African Hip-Hop',
    ],
  ),
  const _BrowseCardData(
    title: 'Rock',
    color: Color(0xFFE91429),
    asset: 'assets/covers/rock.jpg',
    icon: Icons.album,
    query: 'rock',
    subs: [
      'Rock Hits',
      'Classic Rock',
      'Alternative Rock',
      'Indie Rock',
      'Hard Rock',
      'Punk Rock',
      'Pop Rock',
      'Garage Rock',
      'Progressive Rock',
      'Psychedelic Rock',
      'Grunge',
      'Post-Rock',
    ],
  ),
  const _BrowseCardData(
    title: 'Latin',
    color: Color(0xFFE1118B),
    asset: 'assets/covers/latin.jpg',
    icon: Icons.record_voice_over,
    query: 'latin',
    subs: [
      'Reggaeton',
      'Latin Pop',
      'Salsa',
      'Bachata',
      'Merengue',
      'Latin Trap',
      'Latin Hip-Hop',
      'Cumbia',
      'Regional Mexican',
      'Corridos',
      'Brazilian',
      'Latin Classics',
    ],
  ),
  const _BrowseCardData(
    title: 'Mood',
    color: Color(0xFF477D95),
    asset: 'assets/covers/mood.jpg',
    icon: Icons.emoji_emotions,
    query: 'chill mood',
    subs: [
      'Happy',
      'Sad',
      'Chill',
      'Energetic',
      'Romantic',
      'Motivational',
      'Confident',
      'Peaceful',
      'Angry',
      'Nostalgic',
      'Melancholic',
      'Feel Good',
      'Emotional',
      'Dark',
      'Hopeful',
    ],
  ),
  const _BrowseCardData(
    title: 'Charts',
    color: Color(0xFF8D67AB),
    asset: 'assets/covers/charts.jpg',
    query: 'top hits',
    subs: [
      'Global Top 50',
      'Viral 50',
      'Top Songs',
      'Top Albums',
      'Top Artists',
      'Trending',
      'Fastest Rising',
      'Global',
      'Benin',
      'Africa',
      'France',
      'USA',
      'UK',
      'Nigeria',
      'Ghana',
      "Côte d'Ivoire",
    ],
  ),
  const _BrowseCardData(
    title: 'Decades',
    color: Color(0xFF503750),
    asset: 'assets/covers/decades.jpg',
    icon: Icons.history,
    query: 'oldies',
    subs: [
      '2020s',
      '2010s',
      '2000s',
      '1990s',
      '1980s',
      '1970s',
      '1960s',
      '1950s',
      '1940s',
      'Classics',
    ],
  ),
  const _BrowseCardData(
    title: 'Country',
    color: Color(0xFF1DB954),
    asset: 'assets/covers/country.jpg',
    icon: Icons.landscape,
    query: 'country',
    subs: [
      'Country Hits',
      'New Country',
      'Country Pop',
      'Country Rock',
      'Americana',
      'Bluegrass',
      'Outlaw Country',
      'Classic Country',
      'Contemporary Country',
      'Country Love',
      'Country Classics',
    ],
  ),
  const _BrowseCardData(
    title: 'R&B',
    color: Color(0xDC1E3264),
    asset: 'assets/covers/rb.jpg',
    icon: Icons.headphones,
    query: 'r&b',
    subs: [
      'Contemporary R&B',
      'New R&B',
      'R&B Hits',
      'Alternative R&B',
      'Neo Soul',
      '90s R&B',
      '2000s R&B',
      'R&B Love',
      'R&B Chill',
      'Slow Jams',
      'Urban R&B',
    ],
  ),
  const _BrowseCardData(
    title: 'K-Pop',
    color: Color(0xFF148A08),
    asset: 'assets/covers/kpop.jpg',
    icon: Icons.auto_awesome,
    query: 'k-pop',
    subs: [
      'K-Pop Hits',
      'New K-Pop',
      'K-Pop Girl Groups',
      'K-Pop Boy Groups',
      'Soloists',
      'K-R&B',
      'K-Hip-Hop',
      'K-Rock',
      'K-Indie',
      'K-Pop Classics',
      'Korean OST',
    ],
  ),
  const _BrowseCardData(
    title: 'Indie',
    color: Color(0xFF608108),
    asset: 'assets/covers/indie.jpg',
    query: 'indie',
    subs: [
      'Indie Pop',
      'Indie Rock',
      'Indie Folk',
      'Indie Electronic',
      'Dream Pop',
      'Bedroom Pop',
      'Alternative',
      'Shoegaze',
      'Lo-Fi Indie',
      'Indie Classics',
    ],
  ),
  const _BrowseCardData(
    title: 'Workout',
    color: Color(0xFF777777),
    asset: 'assets/covers/workout.jpg',
    icon: Icons.fitness_center,
    query: 'workout',
    subs: [
      'Gym',
      'Running',
      'HIIT',
      'Cardio',
      'Strength Training',
      'Boxing',
      'Cycling',
      'Yoga',
      'Pre-Workout',
      'High Energy',
      'Motivation',
      'Recovery',
    ],
  ),
  const _BrowseCardData(
    title: 'Focus',
    color: Color(0xFF509BF5),
    asset: 'assets/covers/focus.jpg',
    icon: Icons.psychology,
    query: 'focus',
    subs: [
      'Deep Focus',
      'Study',
      'Coding',
      'Reading',
      'Work',
      'Productivity',
      'Instrumental',
      'Ambient',
      'Classical Focus',
      'Lo-Fi Focus',
      'White Noise',
    ],
  ),
  const _BrowseCardData(
    title: 'Comedy',
    color: Color(0xFFE1118B),
    asset: 'assets/covers/comedy.jpg',
    query: 'comedy',
    subs: [
      'Stand-Up',
      'Comedy Podcasts',
      'African Comedy',
      'French Comedy',
      'American Comedy',
      'Sketches',
      'Satire',
      'Interviews',
      'Funny Stories',
      'Dark Comedy',
    ],
  ),
  const _BrowseCardData(
    title: 'News & Politics',
    color: Color(0xFF8D67AB),
    asset: 'assets/covers/newspolitics.jpg',
    query: 'news',
    subs: [
      'World News',
      'Africa',
      'Benin',
      'France',
      'USA',
      'Politics',
      'Economy',
      'Technology',
      'Business',
      'Society',
      'Investigations',
      'Interviews',
      'Daily News',
    ],
  ),
  const _BrowseCardData(
    title: 'Sleep',
    color: Color(0xFF1E3264),
    asset: 'assets/covers/sleep.jpg',
    icon: Icons.bedtime,
    query: 'sleep',
    subs: [
      'Sleep Music',
      'Deep Sleep',
      'Relaxation',
      'Nature Sounds',
      'Rain',
      'Ocean',
      'White Noise',
      'Brown Noise',
      'ASMR',
      'Meditation',
      'Sleep Stories',
      'Baby Sleep',
    ],
  ),
  const _BrowseCardData(
    title: 'Party',
    color: Color(0xFFE13300),
    asset: 'assets/covers/party.jpg',
    icon: Icons.celebration,
    query: 'party',
    subs: [
      'Party Hits',
      'Club',
      'Dance',
      'Afrobeats Party',
      'Hip-Hop Party',
      'French Party',
      'Latin Party',
      'Amapiano Party',
      'House Party',
      'Throwbacks',
      'Pre-Game',
      'Night Out',
    ],
  ),
  const _BrowseCardData(
    title: 'Trending',
    color: Color(0xFF148A08),
    asset: 'assets/covers/trending.jpg',
    icon: Icons.trending_up,
    query: 'top hits',
    subs: [
      'Top FR du Jour',
      'Top US du Jour',
      'Global Hits',
      'Afro Bangers',
      'Viral Now',
      'Rising France',
      'Naija Top',
      'South Africa Heat',
    ],
  ),
  const _BrowseCardData(
    title: 'Bande Originale',
    color: Color(0xFF2E77D0),
    asset: 'assets/covers/bandeoriginale.jpg',
    icon: Icons.movie,
    query: 'bande originale',
    subs: [
      'Bandes-Originales',
      'Disney',
      'Séries TV',
      'Anime',
      'Comédies Musicales',
      'Hans Zimmer',
      'John Williams',
      'Classiques du Cinéma',
    ],
  ),
  const _BrowseCardData(
    title: 'Afro Hits',
    color: Color(0xFFE13300),
    asset: 'assets/covers/afrohits.jpg',
    icon: Icons.stadium,
    query: 'afro hits',
    subs: [
      'Afrobeats',
      'Amapiano',
      'Afro Pop',
      'Afro R&B',
      'Afro Hip-Hop',
      'Afro House',
      'Afro Dancehall',
      'Afro Fusion',
      'African Drill',
      'African Gospel',
      'East Africa',
      'West Africa',
      'Central Africa',
      'Southern Africa',
    ],
  ),
  const _BrowseCardData(
    title: 'Chansons',
    color: Color(0xFF006450),
    asset: 'assets/covers/chansons.jpg',
    icon: Icons.mic_external_on,
    query: 'chanson francaise',
    subs: [
      'Chansons Françaises',
      'Chanson Pop',
      "Chanson d'Amour",
      'Chanson Française Classique',
      'Nouvelle Chanson',
      'Variété Française',
      'Chanson Acoustique',
      'Chanson Triste',
      'Chanson Romantique',
      'Chanson Africaine',
      'Chanson Québécoise',
    ],
  ),
  const _BrowseCardData(
    title: 'Rap Français',
    color: Color(0xFF1E3264),
    asset: 'assets/covers/rapfr.jpg',
    icon: Icons.record_voice_over,
    query: 'rap francais',
    subs: [
      'Rap FR',
      'New Rap FR',
      'Rap Game',
      'Drill FR',
      'Trap FR',
      'Rap Alternatif',
      'Rap Underground',
      'Rap Conscient',
      'Rap Hardcore',
      'Rap Love',
      'Freestyle',
      'Rap 90s',
      'Rap 2000s',
      'Rap 2010s',
      'Rap 2020s',
    ],
  ),
  const _BrowseCardData(
    title: 'Afrobeats',
    color: Color(0xFFBA5D07),
    asset: 'assets/covers/afrobeats.jpg',
    icon: Icons.album,
    query: 'afrobeats',
    subs: [
      'Afrobeats Hits',
      'New Afrobeats',
      'Nigerian Afrobeats',
      'Ghanaian Afrobeats',
      'Beninese Afrobeats',
      'Ivorian Afrobeats',
      'Afro-Pop',
      'Afro-R&B',
      'Afro-Fusion',
      'Afro-Love',
      'Afrobeats Classics',
      'Afrobeats Party',
    ],
  ),
  const _BrowseCardData(
    title: 'Reggae',
    color: Color(0xFF608108),
    asset: 'assets/covers/reggae.jpg',
    icon: Icons.grass,
    query: 'reggae',
    subs: [
      'Roots Reggae',
      'Dancehall',
      'Reggae Fusion',
      'Reggae Love',
      'Dub',
      'Ska',
      'Rocksteady',
      'Reggae Classics',
      'New Reggae',
      'African Reggae',
      'Reggae Party',
    ],
  ),
  const _BrowseCardData(
    title: 'Jazz',
    color: Color(0xFF503750),
    asset: 'assets/covers/jazz.jpg',
    icon: Icons.piano,
    query: 'jazz',
    subs: [
      'Jazz Classics',
      'Smooth Jazz',
      'Contemporary Jazz',
      'Bebop',
      'Swing',
      'Jazz Fusion',
      'Latin Jazz',
      'Soul Jazz',
      'Vocal Jazz',
      'Piano Jazz',
      'African Jazz',
      'Jazz Instrumental',
    ],
  ),
  const _BrowseCardData(
    title: 'Classical',
    color: Color(0xFF509BF5),
    asset: 'assets/covers/classical.jpg',
    icon: Icons.music_note,
    query: 'classical',
    subs: [
      'Classical Hits',
      'Piano',
      'Orchestra',
      'Symphony',
      'Opera',
      'Chamber Music',
      'Baroque',
      'Romantic Era',
      'Modern Classical',
      'Contemporary Classical',
      'Film Scores',
      'Classical for Focus',
      'Classical for Sleep',
    ],
  ),
  const _BrowseCardData(
    title: 'Electronic',
    color: Color(0xFF8400E7),
    asset: 'assets/covers/electronic.jpg',
    icon: Icons.graphic_eq,
    query: 'electronic',
    subs: [
      'EDM',
      'House',
      'Techno',
      'Trance',
      'Dubstep',
      'Drum & Bass',
      'Electro',
      'Future Bass',
      'Ambient',
      'Experimental',
      'Progressive',
      'Dance',
      'Melodic Electronic',
    ],
  ),
  const _BrowseCardData(
    title: 'Rap',
    color: Color(0xFFBA5D07),
    asset: 'assets/covers/rap.jpg',
    icon: Icons.mic,
    query: 'rap',
    subs: [
      'Rap Hits',
      'New Rap',
      'Trap',
      'Drill',
      'Boom Bap',
      'Underground',
      'Conscious Rap',
      'Alternative Rap',
      'Hardcore Rap',
      'Rap Love',
      'Freestyle',
      'International Rap',
    ],
  ),
  const _BrowseCardData(
    title: 'Soul',
    color: Color(0xFFE1118B),
    asset: 'assets/covers/soul.jpg',
    icon: Icons.favorite,
    query: 'soul',
    subs: [
      'Classic Soul',
      'Contemporary Soul',
      'Neo Soul',
      'Soul R&B',
      'Motown',
      'Funk Soul',
      'Gospel Soul',
      'Soul Love',
      'Soul Classics',
      'Alternative Soul',
    ],
  ),
  const _BrowseCardData(
    title: 'Chill',
    color: Color(0xFF477D95),
    asset: 'assets/covers/chill.jpg',
    icon: Icons.beach_access,
    query: 'chill',
    subs: [
      'Chill Hits',
      'Chillout',
      'Lounge',
      'Chill R&B',
      'Chill Rap',
      'Chill Pop',
      'Chill Electronic',
      'Acoustic Chill',
      'Sunset',
      'Late Night',
      'Weekend Chill',
    ],
  ),
  const _BrowseCardData(
    title: 'Metal',
    color: Color(0xFFE13300),
    asset: 'assets/covers/metal.jpg',
    icon: Icons.bolt,
    query: 'metal',
    subs: [
      'Heavy Metal',
      'Metalcore',
      'Death Metal',
      'Black Metal',
      'Thrash Metal',
      'Nu Metal',
      'Alternative Metal',
      'Progressive Metal',
      'Symphonic Metal',
      'Doom Metal',
      'Industrial Metal',
      'Metal Classics',
    ],
  ),
  const _BrowseCardData(
    title: 'Blues',
    color: Color(0xFF2E77D0),
    asset: 'assets/covers/blues.jpg',
    icon: Icons.music_note,
    query: 'blues',
    subs: [
      'Blues Classics',
      'Chicago Blues',
      'Delta Blues',
      'Electric Blues',
      'Acoustic Blues',
      'Blues Rock',
      'Soul Blues',
      'Contemporary Blues',
      'Blues Guitar',
      'Blues Vocals',
    ],
  ),
  const _BrowseCardData(
    title: 'Folk & Acoustic',
    color: Color(0xFF608108),
    asset: 'assets/covers/folkacoustic.jpg',
    icon: Icons.park,
    query: 'folk acoustic',
    subs: [
      'Folk',
      'Indie Folk',
      'Acoustic',
      'Singer-Songwriter',
      'Americana',
      'Country Folk',
      'Traditional Folk',
      'Celtic',
      'African Folk',
      'French Folk',
      'Acoustic Covers',
      'Campfire',
    ],
  ),
  const _BrowseCardData(
    title: 'Gospel',
    color: Color(0xFF503750),
    asset: 'assets/covers/gospel.jpg',
    icon: Icons.church,
    query: 'gospel',
    subs: [
      'Gospel Hits',
      'Contemporary Gospel',
      'African Gospel',
      'Benin Gospel',
      'Nigerian Gospel',
      'Gospel Worship',
      'Praise',
      'Choir',
      'Gospel R&B',
      'Gospel Rap',
      'Gospel Classics',
      'Christian Music',
    ],
  ),
  const _BrowseCardData(
    title: 'Funk',
    color: Color(0xFFE91429),
    asset: 'assets/covers/funk.jpg',
    icon: Icons.music_video,
    query: 'funk',
    subs: [
      'Classic Funk',
      'Funk Soul',
      'P-Funk',
      'Disco Funk',
      'Modern Funk',
      'Funk Rock',
      'Brazilian Funk',
      'Afro Funk',
      'Funk Classics',
      'Funk Party',
    ],
  ),
  const _BrowseCardData(
    title: 'House',
    color: Color(0xFF8400E7),
    asset: 'assets/covers/house.jpg',
    icon: Icons.speaker,
    query: 'house music',
    subs: [
      'Deep House',
      'Afro House',
      'Amapiano',
      'Tech House',
      'Progressive House',
      'Tropical House',
      'Future House',
      'Piano House',
      'Soulful House',
      'Classic House',
      'Melodic House',
      'House Party',
    ],
  ),
  const _BrowseCardData(
    title: 'Lo-Fi Beats',
    color: Color(0xFF1E3264),
    asset: 'assets/covers/lofibeats.jpg',
    icon: Icons.radio,
    query: 'lofi beats',
    subs: [
      'Lo-Fi Hip-Hop',
      'Lo-Fi Chill',
      'Lo-Fi Study',
      'Lo-Fi Focus',
      'Lo-Fi Sleep',
      'Lo-Fi Jazz',
      'Lo-Fi Anime',
      'Lo-Fi Gaming',
      'Lo-Fi Rain',
      'Chillhop',
      'Instrumental Lo-Fi',
    ],
  ),
  const _BrowseCardData(
    title: 'Dancehall',
    color: Color(0xFF148A08),
    asset: 'assets/covers/dancehall.jpg',
    icon: Icons.music_note,
    query: 'dancehall',
    subs: [
      'Dancehall Hits',
      'Reggae Fusion',
      'Old School Dancehall',
      'Bashment',
      'Afro Dancehall',
      'Dancehall Français',
      'Moombahton',
      'Reggaeton Dancehall',
    ],
  ),
  const _BrowseCardData(
    title: 'Romance',
    color: Color(0xFFE1118B),
    asset: 'assets/covers/romance.jpg',
    icon: Icons.favorite_border,
    query: 'romantic love songs',
    subs: [
      'Love Songs',
      'Romantic Pop',
      'R&B Love',
      'Afro Love',
      'French Love',
      'Slow Jams',
      "Valentine's Day",
      'Heartbreak',
      'First Love',
      'Wedding',
      'Couple',
      'Love Classics',
    ],
  ),
  const _BrowseCardData(
    title: 'Desi',
    color: Color(0xFFBA5D07),
    asset: 'assets/covers/desi.jpg',
    icon: Icons.language,
    query: 'desi hits',
    subs: [
      'Bollywood',
      'Indian Pop',
      'Hindi',
      'Punjabi',
      'Tamil',
      'Telugu',
      'Bengali',
      'Marathi',
      'Indian Classical',
      'Bhangra',
      'Desi Hip-Hop',
      'Bollywood Classics',
    ],
  ),
  const _BrowseCardData(
    title: 'Caribbean',
    color: Color(0xFFE13300),
    asset: 'assets/covers/caribbean.jpg',
    icon: Icons.waves,
    query: 'caribbean',
    subs: [
      'Dancehall',
      'Reggae',
      'Soca',
      'Zouk',
      'Kompa',
      'Calypso',
      'Reggaeton',
      'Caribbean Pop',
      'Caribbean Classics',
      'Haitian Music',
      'Jamaican Music',
      'Guadeloupe',
      'Martinique',
    ],
  ),
  const _BrowseCardData(
    title: 'Meditation',
    color: Color(0xFF509BF5),
    asset: 'assets/covers/meditation.jpg',
    icon: Icons.self_improvement,
    query: 'meditation',
    subs: [
      'Guided Meditation',
      'Mindfulness',
      'Breathing',
      'Yoga',
      'Relaxation',
      'Stress Relief',
      'Anxiety Relief',
      'Sleep Meditation',
      'Morning Meditation',
      'Evening Meditation',
      'Spiritual',
      'Nature Sounds',
    ],
  ),
  const _BrowseCardData(
    title: 'Musique Arabe',
    color: Color(0xFF1DB954),
    asset: 'assets/covers/musiquearabe.jpg',
    icon: Icons.language,
    query: 'musique arabe',
    subs: [
      'Hits Arabe',
      'Égypte',
      'Maroc',
      'Algérie',
      'Tunisie',
      'Liban',
      'Raï',
      'Khaliji',
    ],
  ),
  const _BrowseCardData(
    title: 'Rumba Congolaise',
    color: Color(0xFFE1118B),
    asset: 'assets/covers/rumbacongolaise.jpg',
    icon: Icons.graphic_eq,
    query: 'rumba congolaise',
    subs: [
      'Rumba Hits',
      'Rumba Classique',
      'Ndombolo',
      'Congo Kinshasa',
      'Congo Brazzaville',
      'Rumba Moderne',
      'Guitaristes Légendaires',
      'Soukous',
    ],
  ),
  const _BrowseCardData(
    title: 'Drill',
    color: Color(0xFF8D67AB),
    asset: 'assets/covers/drill.jpg',
    icon: Icons.bolt,
    query: 'drill',
    subs: [
      'UK Drill',
      'Drill Français',
      'Brooklyn Drill',
      'Afro Drill',
      'Drill Beats',
      'New York Drill',
      'Drill Australien',
      'Irish Drill',
    ],
  ),
];

class _AssetCategoryCard extends ConsumerWidget {
  const _AssetCategoryCard({
    required this.title,
    required this.color,
    this.asset,
    this.icon,
    this.query,
    this.selected = false,
    this.onTap,
  });

  final String title;
  final Color color;
  final String? asset;
  final IconData? icon;
  final String? query;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Static bundled artwork ONLY: the card image must never change between
    // visits, so no network image is fetched here.
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              top: 12,
              left: 12,
              right: 50,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: spotifyWhite,
                ),
              ),
            ),
            if (selected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: spotifyBlack.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: spotifyWhite,
                    size: 12,
                  ),
                ),
              ),
            if (asset != null)
              Positioned(
                bottom: -14,
                right: -16,
                child: Transform.rotate(
                  angle: 0.3,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        asset!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          icon ?? Icons.music_note,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else if (icon != null)
              Positioned(
                bottom: -2,
                right: -4,
                child: Transform.rotate(
                  angle: 0.3,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon!, color: Colors.white.withValues(alpha: 0.6), size: 28),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Clips/Discover sections moved to discover_all_section.dart
