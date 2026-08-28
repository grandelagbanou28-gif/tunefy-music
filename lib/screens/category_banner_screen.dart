import 'package:flutter/material.dart';
import 'package:muzo/widgets/spotify_back_button.dart';
import 'package:muzo/widgets/spotify_chips.dart';

/// Minimal category page: colored banner + title + back button only.
/// Used by the Browse All grid so tapping a category never shows an empty
/// content page when the network fails.
class CategoryBannerScreen extends StatelessWidget {
  const CategoryBannerScreen({
    super.key,
    required this.title,
    required this.color,
    this.asset,
    this.icon,
  });

  final String title;
  final Color color;
  final String? asset;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: spotifyBlack,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: color,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              leading: const SpotifyBackButton(),
              title: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: spotifyWhite,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              centerTitle: true,
            ),
            SliverToBoxAdapter(child: _banner(context)),
            const SliverPadding(padding: EdgeInsets.only(bottom: 130)),
          ],
        ),
      ),
    );
  }

  Widget _banner(BuildContext context) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, Color.lerp(color, spotifyBlack, 0.75)!],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 20,
            right: 130,
            bottom: 40,
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: spotifyWhite,
                fontSize: 36,
                height: 1.02,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (asset != null)
            Positioned(
              right: 18,
              bottom: 24,
              child: Transform.rotate(
                angle: 0.12,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      asset!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.black26,
                        child: Icon(
                          icon ?? Icons.music_note,
                          color: spotifyWhite,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
