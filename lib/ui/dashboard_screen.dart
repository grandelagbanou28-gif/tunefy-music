import 'package:flutter/material.dart';
import 'package:tunefy/constants/constants.dart';
import 'package:tunefy/providers/player_provider.dart';
import 'package:tunefy/services/premium_service.dart';
import 'package:tunefy/ui/home_screen.dart';
import 'package:tunefy/ui/library_screen.dart';
import 'package:tunefy/ui/search_category_screen.dart';
import 'package:tunefy/services/haptic_service.dart';
import 'package:tunefy/theme/tunefy_theme.dart';

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({super.key});

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    showPremiumPrompt.addListener(_onPremiumPrompt);
  }

  @override
  void dispose() {
    showPremiumPrompt.removeListener(_onPremiumPrompt);
    super.dispose();
  }

  void _onPremiumPrompt() {
    final msg = showPremiumPrompt.value;
    if (msg == null || !mounted) return;
    showPremiumPrompt.value = null;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              const Icon(Icons.star, color: Color(0xFF1DB954), size: 48),
              const SizedBox(height: 16),
              const Text("Passez à Premium", style: TextStyle(fontFamily: "AB", fontSize: 20, color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                msg == 'limite de skips atteinte'
                    ? "Vous avez atteint la limite de 6 skips par heure. Passez à Premium pour des skips illimités."
                    : "Cette fonctionnalité est réservée aux abonnés Premium.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: "AM", fontSize: 13, color: Color(0xFFB3B3B3)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB954),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    PremiumService.activate();
                  },
                  child: const Text("ACTIVER PREMIUM", style: TextStyle(fontFamily: "AB", fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Plus tard", style: TextStyle(fontFamily: "AM", fontSize: 13, color: Color(0xFFB3B3B3))),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      bottomNavigationBar: Container(
        height: 64,
        width: MediaQuery.of(context).size.width,
        color: MyColors.blackColor.withValues(alpha: 0.95),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 45),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedLabelStyle: const TextStyle(fontFamily: "AM", fontSize: 13),
            selectedItemColor: const Color(0xffE5E5E5),
            unselectedItemColor: MyColors.lightGrey,
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            onTap: (value) {
              setState(() {
                _currentIndex = value;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: Image.asset('images/icon_home.png'),
                activeIcon: Image.asset('images/icon_home_active.png'),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'images/icon_search_bottomnav.png',
                ),
                activeIcon: Image.asset(
                  'images/icon_search_active.png',
                  color: MyColors.whiteColor,
                ),
                label: "Search",
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'images/icon_library.png',
                  color: MyColors.lightGrey,
                ),
                activeIcon: Image.asset(
                  'images/icon_library_active.png',
                  color: MyColors.whiteColor,
                ),
                label: "Your Library",
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          SearchCategoryScreen(),
          LibraryScreen(),
        ],
      ),
    );
  }
}
