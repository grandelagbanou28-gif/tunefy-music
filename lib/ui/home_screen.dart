import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tunefy/constants/constants.dart';
import 'package:tunefy/data/home_data.dart';
import 'package:tunefy/models/home_track.dart';
import 'package:tunefy/ui/profile_screen.dart';
import 'package:tunefy/widgets/bottom_player.dart';
import 'package:tunefy/widgets/home_widgets.dart';
import 'package:tunefy/services/haptic_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final sections = HomeData.visibleSections;

    return Scaffold(
      backgroundColor: MyColors.blackColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.04),
              child: CustomScrollView(
                slivers: [
                  _buildHeader(context, w),
                  for (final section in sections) ...[
                    HomeSectionHeader(title: section.title),
                    if (section.type == HomeSectionType.tracks)
                      _buildTrackSection(section.tracks, w),
                    if (section.type == HomeSectionType.artists)
                      _buildArtistSection(section.artists, w),
                    if (section.type == HomeSectionType.albums)
                      _buildAlbumSection(section.albums, w),
                  ],
                  const SliverPadding(padding: EdgeInsets.only(bottom: 140)),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 64,
              child: BottomPlayer(),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildHeader(BuildContext context, double w) {
    final userName = Hive.box('settings').get('userName', defaultValue: '') as String;
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(top: w * 0.07),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticService.tap();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                  },
                  child: CircleAvatar(
                    radius: w * 0.05,
                    backgroundImage: const AssetImage("images/hivefy_logo.png"),
                  ),
                ),
                SizedBox(width: w * 0.03),
                Text(
                  userName.isNotEmpty ? 'Bonjour $userName' : _getGreeting(),
                  style: TextStyle(
                    fontFamily: "AB",
                    color: MyColors.whiteColor,
                    fontSize: w * 0.05,
                  ),
                ),
              ],
            ),
            SizedBox(height: w * 0.04),
            Row(
              children: [
                _buildQuickChip(context, "Liked Songs", "images/liked_songs.png", true, w),
                SizedBox(width: w * 0.03),
                _buildQuickChip(context, "Gims", "images/artists/Drake.jpg", false, w),
              ],
            ),
            SizedBox(height: w * 0.01),
            Row(
              children: [
                _buildQuickChip(context, "21 Savage", "images/home/american-dream.jpg", false, w),
                SizedBox(width: w * 0.03),
                _buildQuickChip(context, "Travis Scott", "images/home/UTOPIA.jpg", false, w),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildQuickChip(BuildContext context, String title, String image, bool isLiked, double w) {
    final chipWidth = (w - w * 0.08 - w * 0.03) / 2;
    return Container(
      height: w * 0.13,
      width: chipWidth,
      decoration: const BoxDecoration(
        color: MyColors.darkGreyColor,
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      child: Row(
        children: [
          if (isLiked)
            Stack(
              alignment: AlignmentDirectional.center,
              children: [
                Container(
                  height: w * 0.13,
                  width: w * 0.13,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5),
                      bottomLeft: Radius.circular(5),
                    ),
                    image: DecorationImage(image: AssetImage("images/liked_songs.png"), fit: BoxFit.cover),
                  ),
                ),
                Image.asset('images/icon_heart_white.png', height: w * 0.05, width: w * 0.05),
              ],
            )
          else
            Container(
              height: w * 0.13,
              width: w * 0.13,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  bottomLeft: Radius.circular(5),
                ),
                image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover),
              ),
            ),
          SizedBox(width: w * 0.02),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: "AB",
                fontSize: w * 0.027,
                color: MyColors.whiteColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildTrackSection(List<HomeTrack> tracks, double w) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: w * 0.38 + 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            return HomeTrackCard(track: tracks[index], index: index);
          },
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildArtistSection(List<HomeArtist> artists, double w) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: w * 0.30 + 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: artists.length,
          itemBuilder: (context, index) {
            return HomeArtistCard(artist: artists[index]);
          },
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildAlbumSection(List<HomeAlbum> albums, double w) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: w * 0.38 + 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: albums.length,
          itemBuilder: (context, index) {
            return HomeAlbumCard(album: albums[index]);
          },
        ),
      ),
    );
  }

}
