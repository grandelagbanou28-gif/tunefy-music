import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tunefy/DI/service_locator.dart';
import 'package:tunefy/bloc/album/album_bloc.dart';
import 'package:tunefy/bloc/album/album_event.dart';
import 'package:tunefy/constants/constants.dart';
import 'package:tunefy/data/model/podcast_models.dart';
import 'package:tunefy/models/track.dart';
import 'package:tunefy/services/podcast_search_service.dart';
import 'package:tunefy/ui/albumview_screen.dart';
import 'package:tunefy/ui/podcast_detail_screen.dart';
import 'package:tunefy/ui/profile_screen.dart';
import 'package:tunefy/ui/setting_screen.dart';
import 'package:tunefy/widgets/album_chip.dart';
import 'package:tunefy/widgets/artist_chip.dart';
import 'package:tunefy/widgets/bottom_player.dart';
import 'package:tunefy/widgets/song_chip.dart';
import 'package:tunefy/services/haptic_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tunefy/theme/tunefy_theme.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _selectedFilter = 0;
  List<PodcastChannel> _podcastChannels = [];
  List<PodcastEpisode> _podcastEpisodes = [];
  bool _isLoadingPodcasts = false;

  @override
  void initState() {
    super.initState();
    _loadPodcasts();
  }

  Future<void> _loadPodcasts() async {
    setState(() => _isLoadingPodcasts = true);
    final channels = await PodcastSearchService.getTopPodcastChannels(limit: 10);
    final episodes = await PodcastSearchService.getPopularPodcasts(limit: 10);
    if (mounted) {
      setState(() {
        _podcastChannels = channels;
        _podcastEpisodes = episodes;
        _isLoadingPodcasts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.blackColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          alignment: AlignmentDirectional.bottomCenter,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 25, top: 25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              HapticService.tap();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingScreen(),
                                ),
                              );
                            },
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage:
                                      AssetImage("images/hivefy_logo.png"),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Your Library",
                                  style: TextStyle(
                                    fontFamily: "AB",
                                    fontSize: 24,
                                    color: MyColors.whiteColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticService.tap();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfileScreen(),
                                ),
                              );
                            },
                            child: Image.asset("images/icon_add.png"),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 33,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => setState(() => _selectedFilter = index),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Container(
                                height: 33,
                                decoration: BoxDecoration(
                                  color: _selectedFilter == index
                                      ? MyColors.whiteColor
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: MyColors.lightGrey,
                                    width: 1,
                                  ),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(15),
                                  ),
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 15),
                                    child: Text(
                                      ["Playlists", "Artists", "Albums", "Podcasts & shows"][index],
                                      style: TextStyle(
                                        fontFamily: "AM",
                                        fontSize: 12,
                                        color: _selectedFilter == index
                                            ? MyColors.blackColor
                                            : MyColors.whiteColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (_selectedFilter == 3) ...[
                    if (_isLoadingPodcasts)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator(color: MyColors.whiteColor)),
                      )
                    else ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Your podcasts",
                                style: TextStyle(
                                  fontFamily: "AB",
                                  fontSize: 18,
                                  color: MyColors.whiteColor,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _podcastChannels.length,
                                  itemBuilder: (context, index) {
                                    final channel = _podcastChannels[index];
                                    return GestureDetector(
                                      onTap: () {
                                        HapticService.tap();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PodcastDetailScreen(
                                              title: channel.title,
                                              imageUrl: channel.imageUrl,
                                              description: channel.description,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 70,
                                              height: 70,
                                              decoration: BoxDecoration(
                                                color: MyColors.darkGreyColor,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(6),
                                                child: channel.imageUrl != null
                                                    ? CachedNetworkImage(
                                                        imageUrl: channel.imageUrl!,
                                                        fit: BoxFit.cover,
                                                        errorWidget: (_, __, ___) => const Center(
                                                          child: Icon(Icons.podcasts, color: MyColors.whiteColor, size: 30),
                                                        ),
                                                      )
                                                    : const Center(
                                                        child: Icon(Icons.podcasts, color: MyColors.whiteColor, size: 30),
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            SizedBox(
                                              width: 70,
                                              child: Text(
                                                channel.title,
                                                style: const TextStyle(
                                                  fontFamily: "AM",
                                                  fontSize: 10,
                                                  color: MyColors.whiteColor,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 15, bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Recent episodes",
                                style: TextStyle(
                                  fontFamily: "AB",
                                  fontSize: 18,
                                  color: MyColors.whiteColor,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final episode = _podcastEpisodes[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GestureDetector(
                                onTap: () {
                                  HapticService.tap();
                                  if (episode.videoId != null) {
                                    final track = Track(
                                      videoId: episode.videoId,
                                      title: episode.title,
                                      artist: episode.channelTitle,
                                      albumImage: episode.imageUrl,
                                    );
                                    playerProvider.playTrack(track);
                                  }
                                },
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: episode.imageUrl != null
                                          ? CachedNetworkImage(
                                              imageUrl: episode.imageUrl!,
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) => Container(
                                                width: 48,
                                                height: 48,
                                                color: MyColors.darkGreyColor,
                                                child: const Icon(Icons.podcasts, color: MyColors.whiteColor, size: 20),
                                              ),
                                            )
                                          : Container(
                                              width: 48,
                                              height: 48,
                                              color: MyColors.darkGreyColor,
                                              child: const Icon(Icons.podcasts, color: MyColors.whiteColor, size: 20),
                                            ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            episode.title,
                                            style: const TextStyle(
                                              fontFamily: "AM",
                                              fontSize: 14,
                                              color: MyColors.whiteColor,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            episode.channelTitle,
                                            style: const TextStyle(
                                              fontFamily: "AM",
                                              fontSize: 12,
                                              color: MyColors.lightGrey,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: _podcastEpisodes.length,
                        ),
                      ),
                    ],
                  ] else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 30, bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Row(
                                  children: [
                                    Image.asset(
                                      "images/arrow_component_down.png",
                                      width: 10,
                                      height: 12,
                                    ),
                                    Image.asset(
                                      "images/arrow_component_up.png",
                                      width: 10,
                                      height: 12,
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                const Text(
                                  "Recently Played",
                                  style: TextStyle(
                                    fontFamily: "AM",
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: MyColors.whiteColor,
                                  ),
                                ),
                              ],
                            ),
                            Image.asset("images/icon_category.png"),
                          ],
                        ),
                      ),
                    ),
                    const _LikedSongsSection(),
                    const _NewEpisodesSection(),
                    SliverToBoxAdapter(
                      child: GestureDetector(
                        onTap: () {
                          HapticService.tap();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BlocProvider(
                                create: (context) {
                                  var bloc = AlbumBloc(locator.get());
                                  bloc.add(AlbumListEvent("Drake"));
                                  return bloc;
                                },
                                child: const AlbumViewScreen(),
                              ),
                            ),
                          );
                        },
                        child: const AlbumChip(
                          image: "For-All-The-Dogs.jpg",
                          albumName: "For All The Dogs",
                          artistName: "Drake",
                          size: 65,
                          isDeletable: false,
                        ),
                      ),
                    ),
                    const ArtistChip(
                      image: '21-Savage.jpg',
                      name: "21 Savage",
                      radius: 35,
                      isDeletable: false,
                    ),
                    const SongChip(
                      image: "UTOPIA.jpg",
                      singerName: 'Travis Scott',
                      songTitle: "I KNOW ?",
                      size: 47,
                      isDeletable: false,
                    ),
                    const ArtistChip(
                      image: "Post-Malone.jpg",
                      name: "Post Malone",
                      radius: 35,
                      isDeletable: false,
                    ),
                    SliverToBoxAdapter(
                      child: GestureDetector(
                        onTap: () {
                          HapticService.tap();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BlocProvider(
                                create: (context) {
                                  var bloc = AlbumBloc(locator.get());
                                  bloc.add(AlbumListEvent("21 Savage"));
                                  return bloc;
                                },
                                child: const AlbumViewScreen(),
                              ),
                            ),
                          );
                        },
                        child: const AlbumChip(
                          image: "american-dream.jpg",
                          albumName: "american dream",
                          artistName: "21 Savage",
                          size: 65,
                          isDeletable: false,
                        ),
                      ),
                    ),
                    const ArtistChip(
                      image: "J-Cole.jpg",
                      name: "J Cole",
                      radius: 35,
                      isDeletable: false,
                    ),
                    const SongChip(
                      image: "AUSTIN.jpg",
                      singerName: 'Post Malone',
                      songTitle: "Landmine",
                      size: 47,
                      isDeletable: false,
                    ),
                  ],
                  const SliverPadding(
                    padding: EdgeInsets.only(bottom: 130),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 64),
              child: BottomPlayer(),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewEpisodesSection extends StatelessWidget {
  const _NewEpisodesSection();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 5, bottom: 15),
        child: Row(
          children: [
            Stack(
              alignment: AlignmentDirectional.center,
              children: [
                Image.asset("images/new_episods.png"),
                Image.asset("images/icon_bell_fill.png"),
              ],
            ),
            const SizedBox(
              width: 10,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "New Episodes",
                  style: TextStyle(
                    fontFamily: "AM",
                    fontSize: 15,
                    color: MyColors.whiteColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Row(
                  children: [
                    Image.asset("images/icon_pin.png"),
                    const SizedBox(width: 5),
                    const Text(
                      "Updated 2 days ago",
                      style: TextStyle(
                        fontFamily: "AM",
                        color: MyColors.lightGrey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LikedSongsSection extends StatelessWidget {
  const _LikedSongsSection();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 15, bottom: 15),
        child: Row(
          children: [
            Stack(
              alignment: AlignmentDirectional.center,
              children: [
                Image.asset("images/liked_songs.png"),
                Image.asset("images/icon_heart_white.png"),
              ],
            ),
            const SizedBox(
              width: 10,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Liked Songs",
                  style: TextStyle(
                    fontFamily: "AM",
                    fontSize: 15,
                    color: MyColors.whiteColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Row(
                  children: [
                    Image.asset("images/icon_pin.png"),
                    const SizedBox(width: 5),
                    const Text(
                      "Playlist . 58 songs",
                      style: TextStyle(
                        fontFamily: "AM",
                        color: MyColors.lightGrey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
