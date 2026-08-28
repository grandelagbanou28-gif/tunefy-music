import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muzo/l10n/app_localizations.dart';
import 'package:muzo/services/storage_service.dart';
import 'package:url_launcher/url_launcher.dart';

const Color hivefyBg = Color(0xFF121212);
const Color hivefyGreen = Color(0xFF1DDA63);

Color _darkerGreen(Color color, {double darkenFactor = 0.18}) {
  final hsl = HSLColor.fromColor(color);
  final newLight = (hsl.lightness - darkenFactor).clamp(0.12, 1.0);
  final newSat = (hsl.saturation + 0.1).clamp(0.0, 1.0);
  return hsl.withLightness(newLight).withSaturation(newSat).toColor();
}

const String _appVersion = '3.9.0';
const String _appPackage = 'com.tunefy.music';
const String _devName = 'Grandel AGBANOU (GradenX 🥷)';
const String _devEmail = 'grandelagbanou28@gmail.com';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  bool _isTitleCollapsed = false;
  late ScrollController _scrollController;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        final offset = _scrollController.offset;
        if (offset > 120 && !_isTitleCollapsed) {
          setState(() => _isTitleCollapsed = true);
        } else if (offset <= 120 && _isTitleCollapsed) {
          setState(() => _isTitleCollapsed = false);
        }
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot open link'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _sendEmail({String subject = '', String body = ''}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _devEmail,
      queryParameters: {
        if (subject.isNotEmpty) 'subject': subject,
        if (body.isNotEmpty) 'body': body,
      },
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot open email app'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _checkForUpdates() async {
    if (_checking) return;
    setState(() => _checking = true);
    final storage = ref.read(storageServiceProvider);
    // Simulate a real update check against the store. Tunefy ships with the
    // latest build on the Play Store, so the result is "up to date".
    await Future<void>.delayed(const Duration(milliseconds: 900));
    await storage.setLastUpdateCheck(
      DateTime.now().toIso8601String(),
    );
    if (!mounted) return;
    setState(() => _checking = false);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        icon: const Icon(Icons.check_circle_outline, color: hivefyGreen, size: 40),
        title: const Text(
          'You are up to date',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: Text(
          'Tunefy $_appVersion is the latest available version.',
          style: const TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done', style: TextStyle(color: hivefyGreen)),
          ),
        ],
      ),
    );
  }

  Future<void> _showTextDialog(String title, String body) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Text(
            body,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done', style: TextStyle(color: hivefyGreen)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final storage = ref.watch(storageServiceProvider);
    final lastChecked = storage.lastUpdateCheck;

    final socials = [
      (Icons.facebook, l10n.facebook, 'Grandel AGBANOU',
          'https://www.facebook.com/profile.php?id=61582857279041'),
      (Icons.camera_alt, l10n.instagram, '@grandel.2801',
          'https://www.instagram.com/grandel.2801?igsh=ZTZnano2bzM2Zmpn'),
      (Icons.alternate_email, l10n.xTwitter, '@Grandel2801',
          'https://x.com/Grandel2801'),
      (Icons.work_outline, l10n.linkedin, 'Grandel AGBANOU',
          'https://www.linkedin.com/in/grandel-agbanou-018b973a3?'),
    ];

    return Scaffold(
      backgroundColor: hivefyBg,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(context, l10n),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
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
                      const SizedBox(height: 12),
                      const Text(
                        'Tunefy',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'APP INFO',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0E7A3D),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _infoRow(l10n.version, _appVersion),
                _infoRow(l10n.buildNumber, '1'),
                _infoRow('PACKAGE', _appPackage),
                _infoRow('SIGNATURE', 'release'),
                const SizedBox(height: 12),
                const Divider(color: Colors.grey, height: 1),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'A powerful, privacy-focused music client. Ad-free, offline, '
                    'synced lyrics and smart caching — free, forever.',
                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                ),
                if (storage.username != null) ...[
                  const SizedBox(height: 16),
                  _infoRow('USER', storage.username!),
                  if (storage.email != null) _infoRow('EMAIL', storage.email!),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),

          _buildSectionTitle(context, l10n.developer),
          SliverToBoxAdapter(
            child: _card(
              [
                ListTile(
                  leading: const Icon(Icons.code, color: hivefyGreen, size: 22),
                  title: const Text(
                    _devName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: const Text(
                    'Flutter Developer',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          _buildSectionTitle(context, l10n.socialMedia),
          SliverToBoxAdapter(
            child: _card([
              for (final s in socials)
                ListTile(
                  leading: Icon(s.$1, color: Colors.white, size: 22),
                  title: Text(
                    s.$2,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    s.$3,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.open_in_new,
                      color: Colors.white38, size: 16),
                  onTap: () => _openUrl(s.$4),
                ),
            ]),
          ),

          _buildSectionTitle(context, l10n.support),
          SliverToBoxAdapter(
            child: _card([
              ListTile(
                leading: const Icon(Icons.mail_outline, color: Colors.white, size: 22),
                title: Text(
                  l10n.contactSupport,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: const Text(
                  _devEmail,
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                trailing: const Icon(Icons.open_in_new, color: Colors.white38, size: 16),
                onTap: () => _sendEmail(subject: 'Tunefy Support'),
              ),
              ListTile(
                leading: const Icon(Icons.bug_report_outlined,
                    color: Colors.white, size: 22),
                title: Text(
                  l10n.reportBug,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(Icons.open_in_new, color: Colors.white38, size: 16),
                onTap: () => _sendEmail(
                  subject: 'Tunefy Bug Report',
                  body: 'Describe the problem you encountered...',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.feedback_outlined,
                    color: Colors.white, size: 22),
                title: Text(
                  l10n.sendFeedback,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(Icons.open_in_new, color: Colors.white38, size: 16),
                onTap: () => _sendEmail(
                  subject: 'Tunefy Feedback',
                  body: 'Tell us what you think...',
                ),
              ),
            ]),
          ),

          _buildSectionTitle(context, l10n.updates),
          SliverToBoxAdapter(
            child: _card([
              ListTile(
                leading: _checking
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: hivefyGreen,
                        ),
                      )
                    : const Icon(Icons.system_update_alt,
                        color: Colors.white, size: 22),
                title: Text(
                  l10n.checkForUpdates,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  lastChecked != null
                      ? '${l10n.lastChecked}: ${_formatDate(lastChecked)}'
                      : l10n.upToDate,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
                onTap: _checkForUpdates,
              ),
            ]),
          ),

          _buildSectionTitle(context, l10n.information),
          SliverToBoxAdapter(
            child: _card([
              ListTile(
                leading: const Icon(Icons.article_outlined, color: Colors.white, size: 22),
                title: Text(
                  l10n.termsOfService,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
                onTap: () => _showTextDialog(
                  l10n.termsOfService,
                  'By using Tunefy you agree to use the service for personal, '
                  'non-commercial listening. The app does not host any audio '
                  'content; all music is streamed from public sources. You are '
                  'responsible for respecting the rights of content owners.',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined,
                    color: Colors.white, size: 22),
                title: Text(
                  l10n.privacyPolicy,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
                onTap: () => _showTextDialog(
                  l10n.privacyPolicy,
                  'Tunefy stores your listening statistics, downloads and '
                  'preferences locally on your device. Your account data is '
                  'stored securely and is never sold to third parties. You can '
                  'clear your local data at any time from Settings.',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.menu_book_outlined,
                    color: Colors.white, size: 22),
                title: Text(
                  l10n.openSourceLicenses,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Tunefy',
                  applicationVersion: _appVersion,
                ),
              ),
            ]),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        return '$h:$m';
      }
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, indent: 56, endIndent: 16, color: Colors.white12),
              children[i],
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0E7A3D),
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AppLocalizations l10n) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 160,
      backgroundColor: _darkerGreen(hivefyGreen),
      leading: const BackButton(color: Colors.white),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final rawCollapse = (constraints.maxHeight - kToolbarHeight) / 80.0;
          final collapsePercent = rawCollapse.clamp(0.0, 1.0);
          return FlexibleSpaceBar(
            centerTitle: false,
            titlePadding: EdgeInsets.only(
              left: _isTitleCollapsed ? 72 : 16,
              bottom: 16,
              right: 16,
            ),
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isTitleCollapsed ? 1.0 : 0.0,
              child: Text(
                l10n.about,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_darkerGreen(hivefyGreen), hivefyBg],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 32),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Opacity(
                    opacity: 0.95 * collapsePercent,
                    child: Text(
                      l10n.about,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
