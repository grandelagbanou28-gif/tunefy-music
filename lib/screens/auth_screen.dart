import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muzo/services/auth_service.dart';
import 'package:muzo/widgets/glass_snackbar.dart';
import 'package:muzo/providers/auth_gate_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  // 0 = intro, 1 = auth form
  int _page = 0;

  late TabController _tabController;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goToAuth({int tab = 0}) {
    _tabController.animateTo(tab);
    setState(() => _page = 1);
  }

  void _back() => setState(() => _page = 0);

  void _skip() {
    // Set guest mode — AuthGate will reactively show the main app.
    ref.read(isGuestModeProvider.notifier).state = true;
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _handleAuth() async {
    if (_isLoading) return;

    final authService = ref.read(authServiceProvider);
    final isLogin = _tabController.index == 0;

    setState(() => _isLoading = true);

    try {
      if (isLogin) {
        if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
          throw Exception('Please fill in all fields');
        }
        await authService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        if (_usernameController.text.isEmpty ||
            _emailController.text.isEmpty ||
            _passwordController.text.isEmpty) {
          throw Exception('Please fill in all fields');
        }
        await authService.signup(
          _usernameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }

      if (mounted) {
        showGlassSnackBar(context, 'Welcome to Tunefy!');
        // AuthGate watches authServiceProvider and will reactively
        // switch to MainLayout+HomeScreen now that auth token is set.
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Colors.white;

    const spotifyGreen = Color(0xFF1DB954);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // Green/black gradient background
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.6),
                  radius: 1.4,
                  colors: [
                    const Color(0xFF0F6B2F).withValues(alpha: 0.65),
                    const Color(0xFF084018).withValues(alpha: 0.35),
                    const Color(0xFF000000),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          // Background decorative orbs
          Positioned(
            top: -120, left: -80,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: Container(
                width: 340, height: 340,
                decoration: BoxDecoration(shape: BoxShape.circle, color: spotifyGreen.withValues(alpha: 0.18)),
              ),
            ),
          ),
          Positioned(
            bottom: -80, right: -60,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: Container(
                width: 280, height: 280,
                decoration: BoxDecoration(shape: BoxShape.circle, color: spotifyGreen.withValues(alpha: 0.12)),
              ),
            ),
          ),

          // Page content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (child, anim) => SlideTransition(
              position: Tween<Offset>(
                begin: _page == 0
                    ? const Offset(-1, 0)
                    : const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
            child: _page == 0
                ? _IntroPage(
                    key: const ValueKey('intro'),
                    onLogin: () => _goToAuth(tab: 0),
                    onSignup: () => _goToAuth(tab: 1),
                    onGuest: _skip,
                    onSurface: onSurface,
                    isDark: true,
                  )
                : _AuthPage(
                    key: const ValueKey('auth'),
                    tabController: _tabController,
                    usernameController: _usernameController,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    isLoading: _isLoading,
                    obscurePassword: _obscurePassword,
                    onTogglePassword: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onAuth: _handleAuth,
                    onBack: _back,
                    onSurface: onSurface,
                    isDark: true,
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// INTRO PAGE
// ─────────────────────────────────────────────
class _IntroPage extends ConsumerWidget {
  final VoidCallback onLogin;
  final VoidCallback onSignup;
  final VoidCallback onGuest;
  final Color onSurface;
  final bool isDark;

  const _IntroPage({
    super.key,
    required this.onLogin,
    required this.onSignup,
    required this.onGuest,
    required this.onSurface,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Logo badge (centered, premium)
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1DB954), Color(0xFF0B6B31)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1DB954).withValues(alpha: 0.4),
                      blurRadius: 32,
                      spreadRadius: -8,
                    ),
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Image.asset(
                  'assets/hivefy_icon.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.music_note_rounded,
                    color: Colors.black,
                    size: 48,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Wordmark
            const Text(
              'Tunefy',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 8),

            // Tagline
            const Text(
              'MUSIC CLIENT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1DB954),
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 40),

            // Artist avatars row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _artistAvatar('assets/ninho.jpg'),
                Transform.translate(
                  offset: const Offset(-10, 0),
                  child: _artistAvatar('assets/gazo.jpg'),
                ),
                Transform.translate(
                  offset: const Offset(-20, 0),
                  child: _artistAvatar('assets/tiakola.jpg'),
                ),
                Transform.translate(
                  offset: const Offset(-30, 0),
                  child: _artistAvatar('assets/jul.jpg'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // App description
            const Text(
              'A powerful, privacy-focused music client. Ad-free, offline, synced lyrics and smart caching — free, forever.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0x99FFFFFF),
                height: 1.5,
              ),
            ),

            const Spacer(flex: 3),

            // CTA Buttons
            if (!Platform.isWindows) ...[
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: () async {
                    final authService = ref.read(authServiceProvider);
                    try {
                      await authService.loginWithGoogle();
                      if (context.mounted) {
                        showGlassSnackBar(context, 'Signed in with Google');
                        // AuthGate watches authServiceProvider and will
                        // reactively switch to MainLayout+HomeScreen.
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showGlassSnackBar(context, e.toString().replaceAll('Exception: ', ''));
                      }
                    }
                  },
                  icon: SvgPicture.asset(
                    'assets/google_logo.svg',
                    width: 20,
                    height: 20,
                  ),
                  label: const Text(
                    'Continue with Google',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF121212),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: onSignup,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  elevation: 0,
                ),
                child: const Text('Create account',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: onLogin,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: const Text('Log in',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: onGuest,
                child: Text(
                  'Continue as Guest',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.45),
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _artistAvatar(String assetPath) {
    return Container(
      width: 60,
      height: 60,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1DB954).withValues(alpha: 0.25),
            blurRadius: 12,
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFF1DB954).withValues(alpha: 0.15),
            child: const Icon(Icons.person_rounded, color: Color(0xFF1DB954), size: 26),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// AUTH FORM PAGE (Login / Signup tabs)
// ─────────────────────────────────────────────
class _AuthPage extends StatelessWidget {
  final TabController tabController;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onAuth;
  final VoidCallback onBack;
  final Color onSurface;
  final bool isDark;

  const _AuthPage({
    super.key,
    required this.tabController,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onAuth,
    required this.onBack,
    required this.onSurface,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Back button
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface, size: 20),
              onPressed: onBack,
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Heading
                  Text(
                    'Welcome back',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: onSurface,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to your account or create a new one',
                    style: TextStyle(
                      fontSize: 14,
                      color: onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tab bar
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBar(
                      controller: tabController,
                      indicator: BoxDecoration(
                        color: const Color(0xFF1DB954),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorPadding: const EdgeInsets.all(4),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.black,
                      unselectedLabelColor: onSurface.withValues(alpha: 0.5),
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      dividerColor: Colors.transparent,
                      tabs: const [Tab(text: 'Log in'), Tab(text: 'Sign up')],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Forms
                  SizedBox(
                    height: 260,
                    child: TabBarView(
                      controller: tabController,
                      children: [
                        // Login tab
                        Column(
                          children: [
                            _buildField(context, controller: emailController,
                                hint: 'Email', icon: FluentIcons.mail_24_regular),
                            const SizedBox(height: 14),
                            _buildField(context, controller: passwordController,
                                hint: 'Password', icon: FluentIcons.lock_closed_24_regular,
                                isPassword: true,
                                obscure: obscurePassword,
                                onToggle: onTogglePassword),
                          ],
                        ),
                        // Signup tab
                        Column(
                          children: [
                            _buildField(context, controller: usernameController,
                                hint: 'Username', icon: FluentIcons.person_24_regular),
                            const SizedBox(height: 14),
                            _buildField(context, controller: emailController,
                                hint: 'Email', icon: FluentIcons.mail_24_regular),
                            const SizedBox(height: 14),
                            _buildField(context, controller: passwordController,
                                hint: 'Password', icon: FluentIcons.lock_closed_24_regular,
                                isPassword: true,
                                obscure: obscurePassword,
                                onToggle: onTogglePassword),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: isLoading
                        ? Center(
                              child: SizedBox(
                                height: 24, width: 24,
                                child: CircularProgressIndicator(
                                    color: const Color(0xFF1DB954), strokeWidth: 2),
                              ),
                            )
                          : FilledButton(
                            onPressed: onAuth,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1DB954),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28)),
                            ),
                            child: AnimatedBuilder(
                              animation: tabController,
                              builder: (_, __) => Text(
                                tabController.index == 0 ? 'Log in' : 'Create account',
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && obscure,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: const Color(0xFF1DB954),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.45), size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscure
                      ? FluentIcons.eye_24_regular
                      : FluentIcons.eye_off_24_regular,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 20,
                ),
                onPressed: onToggle,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1DB954), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      ),
    );
  }
}
