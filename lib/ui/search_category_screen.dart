import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tunefy/constants/constants.dart';
import 'package:tunefy/ui/search_screen.dart';
import 'package:tunefy/ui/category_screen.dart';
import 'package:tunefy/ui/scan_spotify_code.dart';
import 'package:tunefy/widgets/bottom_player.dart';
import 'package:tunefy/services/haptic_service.dart';
import 'package:tunefy/theme/tunefy_theme.dart';

class SpotifyCategory {
  final String id;
  final String name;
  final Color color;
  final String imageUrl;

  const SpotifyCategory({
    required this.id,
    required this.name,
    required this.color,
    required this.imageUrl,
  });
}

class SearchCategoryScreen extends StatefulWidget {
  const SearchCategoryScreen({super.key});

  @override
  State<SearchCategoryScreen> createState() => _SearchCategoryScreenState();
}

class _SearchCategoryScreenState extends State<SearchCategoryScreen> {
  static const List<SpotifyCategory> _categories = [
    SpotifyCategory(id: 'pop', name: 'Pop', color: Color(0xff148A08), imageUrl: 'https://picsum.photos/id/1080/200/200'),
    SpotifyCategory(id: 'hiphop', name: 'Hip-Hop', color: Color(0xffBA5D07), imageUrl: 'https://picsum.photos/id/1012/200/200'),
    SpotifyCategory(id: 'rock', name: 'Rock', color: Color(0xffE91429), imageUrl: 'https://picsum.photos/id/1019/200/200'),
    SpotifyCategory(id: 'latin', name: 'Latin', color: Color(0xffE1118C), imageUrl: 'https://picsum.photos/id/1025/200/200'),
    SpotifyCategory(id: 'mood', name: 'Humeur', color: Color(0xff477D95), imageUrl: 'https://picsum.photos/id/1035/200/200'),
    SpotifyCategory(id: 'dance', name: 'Dance/Électro', color: Color(0xff0D73EC), imageUrl: 'https://picsum.photos/id/1044/200/200'),
    SpotifyCategory(id: 'indie', name: 'Indie', color: Color(0xff608108), imageUrl: 'https://picsum.photos/id/1043/200/200'),
    SpotifyCategory(id: 'workout', name: 'Sport', color: Color(0xff777777), imageUrl: 'https://picsum.photos/id/1060/200/200'),
    SpotifyCategory(id: 'country', name: 'Country', color: Color(0xffB06239), imageUrl: 'https://picsum.photos/id/1058/200/200'),
    SpotifyCategory(id: 'rnb', name: 'R&B', color: Color(0xff8D67AB), imageUrl: 'https://picsum.photos/id/1062/200/200'),
    SpotifyCategory(id: 'kpop', name: 'K-Pop', color: Color(0xff0D73EC), imageUrl: 'https://picsum.photos/id/1074/200/200'),
    SpotifyCategory(id: 'chill', name: 'Détente', color: Color(0xff509BF5), imageUrl: 'https://picsum.photos/id/1015/200/200'),
    SpotifyCategory(id: 'sleep', name: 'Sommeil', color: Color(0xff1E3264), imageUrl: 'https://picsum.photos/id/1045/200/200'),
    SpotifyCategory(id: 'party', name: 'Fête', color: Color(0xffE13300), imageUrl: 'https://picsum.photos/id/1059/200/200'),
    SpotifyCategory(id: 'romance', name: 'Romance', color: Color(0xffDB0059), imageUrl: 'https://picsum.photos/id/1027/200/200'),
    SpotifyCategory(id: 'focus', name: 'Concentration', color: Color(0xff503D58), imageUrl: 'https://picsum.photos/id/1069/200/200'),
    SpotifyCategory(id: 'jazz', name: 'Jazz', color: Color(0xff477D95), imageUrl: 'https://picsum.photos/id/1056/200/200'),
    SpotifyCategory(id: 'classical', name: 'Classique', color: Color(0xff7D4B32), imageUrl: 'https://picsum.photos/id/1048/200/200'),
    SpotifyCategory(id: 'metal', name: 'Metal', color: Color(0xff537AA1), imageUrl: 'https://picsum.photos/id/1065/200/200'),
    SpotifyCategory(id: 'reggaeton', name: 'Reggaeton', color: Color(0xffE1118C), imageUrl: 'https://picsum.photos/id/1070/200/200'),
    SpotifyCategory(id: 'afro', name: 'Afrobeats', color: Color(0xff148A08), imageUrl: 'https://picsum.photos/id/1084/200/200'),
    SpotifyCategory(id: 'gaming', name: 'Gaming', color: Color(0xff503D58), imageUrl: 'https://picsum.photos/id/1083/200/200'),
    SpotifyCategory(id: 'anime', name: 'Anime', color: Color(0xffE13300), imageUrl: 'https://picsum.photos/id/1079/200/200'),
    SpotifyCategory(id: 'charts', name: 'Charts', color: Color(0xff8D67AB), imageUrl: 'https://picsum.photos/id/1064/200/200'),
    SpotifyCategory(id: 'decades', name: 'Par décennies', color: Color(0xff8D67AB), imageUrl: 'https://picsum.photos/id/1040/200/200'),
    SpotifyCategory(id: 'comedy', name: 'Comédie', color: Color(0xffE13300), imageUrl: 'https://picsum.photos/id/1067/200/200'),
    SpotifyCategory(id: 'singer', name: 'Chanteur-auteur', color: Color(0xffBA5D07), imageUrl: 'https://picsum.photos/id/1028/200/200'),
    SpotifyCategory(id: 'ambient', name: 'Ambient', color: Color(0xff509BF5), imageUrl: 'https://picsum.photos/id/1036/200/200'),
    SpotifyCategory(id: 'reggae', name: 'Reggae', color: Color(0xff608108), imageUrl: 'https://picsum.photos/id/1039/200/200'),
    SpotifyCategory(id: 'blues', name: 'Blues', color: Color(0xff477D95), imageUrl: 'https://picsum.photos/id/1047/200/200'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.blackColor,
      resizeToAvoidBottomInset: false,
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
                      padding: const EdgeInsets.only(top: 30, bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Search",
                            style: TextStyle(fontFamily: "AB", fontSize: 25, color: MyColors.whiteColor),
                          ),
                          GestureDetector(
                            onTap: () { HapticService.tap(); Navigator.push(context, tunefyRoute(ScanSpotifyCodeScreen())); }
                            child: Image.asset("images/icon_camera.png"),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const _SearchBox(),
                  const SliverPadding(padding: EdgeInsets.only(top: 15)),
                  SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.65,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final cat = _categories[index];
                        return _CategoryTile(category: cat);
                      },
                      childCount: _categories.length,
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 130)),
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

class _SearchBox extends StatelessWidget {
  const _SearchBox();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        height: 46,
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
          color: MyColors.whiteColor,
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: InkWell(
            onTap: () {
              HapticService.tap();
              Navigator.push(context, tunefyRoute(const SearchScreen()));
            },
            child: Row(
              children: [
                Image.asset("images/icon_search_black.png"),
                const SizedBox(width: 15),
                const Text(
                  "What do you want to listen to?",
                  style: TextStyle(fontFamily: "AB", color: MyColors.darkGreyColor, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final SpotifyCategory category;

  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.tap();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CategoryScreen(title: category.name, color: category.color)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: category.color,
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Transform.rotate(
                angle: 0.4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: category.imageUrl,
                    width: 85,
                    height: 85,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 300),
                    placeholder: (_, __) => Container(color: category.color),
                    errorWidget: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.music_note, color: Colors.white.withValues(alpha: 0.5), size: 32),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 14,
              child: Text(
                category.name,
                style: const TextStyle(
                  fontFamily: "AB",
                  fontSize: 17,
                  color: MyColors.whiteColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
