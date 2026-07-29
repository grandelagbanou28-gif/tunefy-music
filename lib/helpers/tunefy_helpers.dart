import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tunefy/models/home_track.dart';
import 'package:tunefy/models/track.dart';
import 'package:tunefy/services/haptic_service.dart';
import 'package:tunefy/DI/service_locator.dart';
import 'package:tunefy/theme/tunefy_colors.dart';

final ValueNotifier<HomeTrack?> globalActiveTrack = ValueNotifier(null);
final ValueNotifier<bool> globalIsPlaying = ValueNotifier(false);

void haptic() => HapticService.tap();
void hapticMedium() => HapticFeedback.mediumImpact();

void selectTrack(HomeTrack track) {
  HapticFeedback.lightImpact();
  globalActiveTrack.value = track;
  globalIsPlaying.value = true;
  final dur = parseDuration(track.duration);
  final trackModel = Track(
    videoId: track.videoId,
    title: track.title,
    artist: track.artist,
    albumImage: track.imageUrl,
    duration: dur,
  );
  playerProvider.playTrack(trackModel);
}

Duration parseDuration(String dur) {
  final parts = dur.split(':');
  if (parts.length == 2) {
    return Duration(minutes: int.tryParse(parts[0]) ?? 0, seconds: int.tryParse(parts[1]) ?? 0);
  }
  return Duration.zero;
}

void toggleGlobalPlay() {
  if (globalActiveTrack.value == null) return;
  haptic();
  playerProvider.togglePlay();
}

Widget img(String path, {required double w, required double h, BoxFit fit = BoxFit.cover, Widget Function(BuildContext, String, Object)? err}) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return CachedNetworkImage(
      imageUrl: path, width: w, height: h, fit: fit,
      placeholder: (_, __) => Container(width: w, height: h, color: TunefyColors.darkCard),
      errorWidget: err ?? ((_, __, ___) => Container(width: w, height: h, color: TunefyColors.darkCard, child: const Icon(Icons.music_note, color: TunefyColors.grey))),
    );
  }
  return Image.asset(path, width: w, height: h, fit: fit, errorBuilder: err != null ? (ctx, e, s) => err(ctx, '$e', s ?? StackTrace.empty) : null);
}

class TrackImage extends StatelessWidget {
  final HomeTrack track;
  final double width;
  final double height;
  const TrackImage({super.key, required this.track, this.width = 100, this.height = 100});

  @override
  Widget build(BuildContext context) {
    final deezerUrl = track.imageUrl ?? '';
    final localArtistImg = artistImage(track.artist);
    final assetPath = 'assets/tracks/${track.videoId}.jpg';
    if (deezerUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: deezerUrl, width: width, height: height, fit: BoxFit.cover,
        placeholder: (_, __) => _gradient(),
        errorWidget: (_, __, ___) {
          if (localArtistImg != null) {
            return Image.asset(localArtistImg, width: width, height: height, fit: BoxFit.cover,
              errorBuilder: (_, ___, ____) => _ytFallback());
          }
          return _ytFallback();
        },
      );
    }

    return Image.asset(
      assetPath, width: width, height: height, fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        if (localArtistImg != null) {
          return Image.asset(localArtistImg, width: width, height: height, fit: BoxFit.cover,
            errorBuilder: (_, ___, ____) => _ytFallback());
        }
        return _ytFallback();
      },
    );
  }

  Widget _ytFallback() {
    return CachedNetworkImage(
      imageUrl: 'https://i.ytimg.com/vi/${track.videoId}/hqdefault.jpg',
      width: width, height: height, fit: BoxFit.cover,
      placeholder: (_, __) => _gradient(),
      errorWidget: (_, __, ___) => _gradient(),
    );
  }

  Widget _gradient() {
    final color = trackColor(track);
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.6)])),
    );
  }
}

const Map<String, String> artistImages = {
  'Drake': 'images/artists/Drake.jpg',
  'Travis Scott': 'images/artists/Travis-Scott.jpg',
  'Future': 'images/artists/Future.jpg',
  'Lil Baby': 'images/artists/Lil Baby.jpg',
  'Kendrick Lamar': 'images/artists/Kendrick-Lamar.jpg',
  'J. Cole': 'images/artists/J-Cole.jpg',
  'Eminem': 'images/artists/Eminem.jpg',
  'Nicki Minaj': 'images/artists/Nicki-Minaj.jpg',
  'Cardi B': 'images/artists/Cardi-B.jpg',
  '21 Savage': 'images/artists/21-Savage.jpg',
  'Adele': 'images/artists/Adele.jpg',
  'Post Malone': 'images/artists/Post-Malone.jpg',
  'DaBaby': 'images/artists/DaBaby.jpg',
  'Doja Cat': 'images/artists/Doja-Cat.jpg',
  'Snoop Dogg': 'images/artists/Snoop Dogg.jpg',
  'Lil Wayne': 'images/artists/Lil-Wayne.jpg',
  'JAY-Z': 'images/artists/JAY-Z.jpg',
  'Kanye West': 'images/artists/Kanye-West.jpg',
  'JID': 'images/artists/JID.jpg',
  'Metro Boomin': 'images/artists/Metro-Boomin.jpg',
  'Tyler, The Creator': 'images/artists/Tyler-The-Creator.jpg',
  'Megan Thee Stallion': 'images/artists/Megan-Thee-Stallion.jpg',
  'Gims': 'images/artists/Gims.jpg',
  'Ninho': 'images/artists/Ninho.jpg',
  'Jul': 'images/artists/Jul.jpg',
  'Booba': 'images/artists/Booba.jpg',
  'SCH': 'images/artists/SCH.jpg',
  'Niska': 'images/artists/Niska.jpg',
  'Gazo': 'images/artists/Gazo.jpg',
  'Werenoi': 'images/artists/Werenoi.jpg',
  'Tiakola': 'images/artists/Tiakola.jpg',
  'SDM': 'images/artists/SDM.jpg',
  'Damso': 'images/artists/Damso.jpg',
  'Kaaris': 'images/artists/Kaaris.jpg',
  'Soolking': 'images/artists/Soolking.jpg',
  'Black M': 'images/artists/Black-M.jpg',
  'Nekfeu': 'images/artists/Nekfeu.jpg',
  'Innoss\'B': 'images/artists/Innoss-B.jpg',
  'Fally Ipupa': 'images/artists/Fally-Ipupa.jpg',
  'Koba LaD': 'images/artists/Koba-LaD.jpg',
  'Vano Baby': 'images/artists/Vano-Baby.jpg',
  'Central Cee': 'images/artists/Central-Cee.jpg',
  'Asake': 'images/artists/Asake.jpg',
  'Burna Boy': 'images/artists/Burna-Boy.jpg',
  'Wizkid': 'images/artists/Wizkid.jpg',
  'Rema': 'images/artists/Rema.jpg',
  'The Weeknd': 'images/artists/The-Weeknd.jpg',
};

const List<Color> gradientColors = [
  Color(0xFF1DB954), Color(0xFFE91E63), Color(0xFF9C27B0),
  Color(0xFF3F51B5), Color(0xFF00BCD4), Color(0xFFFF5722),
  Color(0xFF607D8B), Color(0xFF795548), Color(0xFF4CAF50),
  Color(0xFFFF9800), Color(0xFF2196F3), Color(0xFFF44336),
  Color(0xFF673AB7), Color(0xFF009688), Color(0xFFFFEB3B),
  Color(0xFF8BC34A), Color(0xFFFF6F00), Color(0xFF1565C0),
  Color(0xFFAD1457), Color(0xFF00695C),
];

String? artistImage(String artist) {
  for (final entry in artistImages.entries) {
    if (artist.toLowerCase().contains(entry.key.toLowerCase())) return entry.value;
  }
  return null;
}

Color trackColor(HomeTrack t) {
  return gradientColors[t.title.hashCode.abs() % gradientColors.length];
}

const Set<int> explicitIndices = {0, 3, 7, 11, 15, 19, 23, 27, 31, 35, 39, 43, 47, 51, 55, 59, 63, 67, 71, 75};
