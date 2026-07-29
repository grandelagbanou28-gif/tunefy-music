import 'package:flutter/material.dart';
import 'package:tunefy/constants/constants.dart';
import 'package:tunefy/widgets/bottom_player.dart';
import 'package:tunefy/services/haptic_service.dart';
import 'package:tunefy/services/premium_service.dart';
import 'package:tunefy/theme/tunefy_theme.dart';
import 'package:tunefy/ui/setting_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static void _showProfileMenu(BuildContext context) {
    HapticService.tap();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            _MenuTile(Icons.person_outline, 'Edit Profile', () { Navigator.pop(ctx); Navigator.push(ctx, MaterialPageRoute(builder: (_) => const SettingScreen())); }),
            _MenuTile(Icons.share_outlined, 'Share Profile', () { Navigator.pop(ctx); }),
            _MenuTile(
              PremiumService.isPremium ? Icons.star : Icons.star_outline,
              PremiumService.isPremium ? 'Premium Activé' : 'Get Premium',
              () {
                PremiumService.toggle();
                Navigator.pop(ctx);
              },
              badge: PremiumService.isPremium ? null : 'Premium',
            ),
            const Divider(color: Color(0xFF282828), height: 1),
            _MenuTile(Icons.settings_outlined, 'Settings', () { Navigator.pop(ctx); Navigator.push(ctx, MaterialPageRoute(builder: (_) => const SettingScreen())); }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        alignment: AlignmentDirectional.bottomCenter,
        children: [
          Column(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xff101010), width: 0),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xff00667B), Color(0xff002F38), Color(0xff101010)],
                    ),
                  ),
                  child: const _ProfileHeader(),
                ),
              ),
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xff101010), width: 0),
                    color: const Color(0xff101010),
                  ),
                  child: const _ProfilePlaylists(),
                ),
              ),
            ],
          ),
          const BottomPlayer(),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  const _MenuTile(this.icon, this.label, this.onTap, {this.badge});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 22),
      title: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontFamily: 'AM', fontSize: 14, color: Colors.white))),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF1DB954), borderRadius: BorderRadius.circular(4)),
              child: Text(badge!, style: const TextStyle(fontFamily: 'AM', fontSize: 10, color: Colors.black, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _ProfilePlaylists extends StatelessWidget {
  const _ProfilePlaylists();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(
          height: 10,
        ),
        Image.asset("images/shazam_playlist.png"),
        const SizedBox(
          height: 5,
        ),
        Image.asset("images/roadtrip_playlist.png"),
        const SizedBox(
          height: 5,
        ),
        Image.asset("images/study_playlist.png"),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "See all playlists",
                style: TextStyle(
                  fontFamily: "AM",
                  fontSize: 15,
                  color: MyColors.whiteColor,
                ),
              ),
              Image.asset("images/icon_arrow_right.png"),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 40,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  HapticService.tap();
                  Navigator.pop(context);
                },
                child: Image.asset("images/icon_arrow_left.png"),
              ),
              GestureDetector(
                onTap: () => ProfileScreen._showProfileMenu(context),
                child: Image.asset(
                  "images/icon_more.png",
                  color: MyColors.whiteColor,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 55,
                  backgroundImage: AssetImage("images/hivefy_logo.png"),
                ),
                const SizedBox(height: 35),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 31,
                      width: 105,
                      decoration: BoxDecoration(
                        color: const Color(0xff3E3F3F),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Center(
                        child: Text(
                          "Edit Profile",
                          style: TextStyle(fontFamily: "AB", color: MyColors.whiteColor, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 65,
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '23',
                          style: TextStyle(
                            fontFamily: "AM",
                            fontSize: 12,
                            color: MyColors.whiteColor,
                          ),
                        ),
                        Text(
                          "PlayLists",
                          style: TextStyle(
                            fontFamily: "AM",
                            fontSize: 12,
                            color: MyColors.lightGrey,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '58',
                          style: TextStyle(
                            fontFamily: "AM",
                            fontSize: 12,
                            color: MyColors.whiteColor,
                          ),
                        ),
                        Text(
                          "Followers",
                          style: TextStyle(
                            fontFamily: "AM",
                            fontSize: 10,
                            color: MyColors.lightGrey,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '43',
                          style: TextStyle(
                            fontFamily: "AM",
                            fontSize: 12,
                            color: MyColors.whiteColor,
                          ),
                        ),
                        Text(
                          "Following",
                          style: TextStyle(
                            fontFamily: "AM",
                            fontSize: 10,
                            color: MyColors.lightGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 30),
            child: Text(
              "Playlists",
              style: TextStyle(
                fontFamily: "AM",
                fontWeight: FontWeight.w400,
                color: MyColors.whiteColor,
                fontSize: 19,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
