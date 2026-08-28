import 'package:flutter/material.dart';
import 'package:muzo/widgets/spotify_chips.dart';

/// Spotify's standard top-left back chevron with a proper 40px tap target.
class SpotifyBackButton extends StatelessWidget {
  const SpotifyBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed ?? () => Navigator.maybePop(context),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(Icons.arrow_back_ios_new, color: spotifyWhite, size: 22),
      ),
    );
  }
}
