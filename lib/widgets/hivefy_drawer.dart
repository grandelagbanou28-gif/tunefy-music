import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muzo/screens/features/about_screen.dart';
import 'package:muzo/screens/features/language_screen.dart';
import 'package:muzo/screens/features/sound_capsule_screen.dart';
import 'package:muzo/screens/profile_screen.dart';
import 'package:muzo/screens/settings_screen.dart';
import 'package:muzo/services/storage_service.dart';
import 'package:muzo/utils/page_routes.dart';
import 'package:muzo/l10n/app_localizations.dart';

const Color hivefyBgColor = Color(0xFF121212);
const Color hivefyGreen = Color(0xFF1DDA63);

class HivefyDrawer extends ConsumerWidget {
  final VoidCallback onClose;

  const HivefyDrawer({super.key, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageServiceProvider);
    final l10n = AppLocalizations.of(context);
    final username = storage.username ?? 'User';
    final email = storage.email;

    void navigate(Widget page) {
      onClose();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(SlidePageRoute(page: page));
      });
    }

    return Drawer(
      backgroundColor: hivefyBgColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: hivefyGreen,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/hivefy_icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: () => navigate(const ProfileScreen()),
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          email ?? l10n.viewProfile,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Divider(color: Colors.grey.shade800, height: 0.7),
            const SizedBox(height: 8),

            _DrawerItem(
              icon: Icons.bubble_chart_outlined,
              title: l10n.soundCapsule,
              onTap: () => navigate(const SoundCapsuleScreen()),
            ),
            _DrawerItem(
              icon: Icons.settings_outlined,
              title: l10n.settingsStorage,
              onTap: () => navigate(const SettingsScreen()),
            ),
            _DrawerItem(
              icon: Icons.language,
              title: l10n.language,
              onTap: () => navigate(const LanguageScreen()),
            ),
            _DrawerItem(
              icon: Icons.info_outline,
              title: l10n.about,
              onTap: () => navigate(const AboutScreen()),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 16),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Tunefy v3.9.0\n",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _DrawerItem({required this.icon, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {},
      splashColor: Colors.white10,
      highlightColor: Colors.white10,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Icon(icon, color: Colors.white70, size: 26),
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
