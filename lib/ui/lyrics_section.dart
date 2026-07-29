import 'package:flutter/material.dart';
import 'package:tunefy/constants/constants.dart';
import 'package:animations/animations.dart';
import 'package:tunefy/ui/lyrics_screen.dart';
import 'package:tunefy/DI/service_locator.dart';
import 'package:tunefy/services/haptic_service.dart';
import 'package:tunefy/theme/tunefy_theme.dart';

class LyricsSection extends StatelessWidget {
  const LyricsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xff2c7c93),
            Color(0xff215260),
            Color(0xff141517),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 100),
              OpenContainer(
                openElevation: 0.0,
                closedElevation: 0.0,
                transitionDuration: const Duration(milliseconds: 400),
                middleColor: Colors.transparent,
                closedColor: Colors.transparent,
                openColor: Colors.transparent,
                closedBuilder: (context, action) {
                  return const _LyricsSection();
                },
                openBuilder: (context, action) {
                  return LyricsScreen(track: playerProvider.currentTrack);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LyricsSection extends StatefulWidget {
  const _LyricsSection();

  @override
  State<_LyricsSection> createState() => _LyricsSectionState();
}

class _LyricsSectionState extends State<_LyricsSection> {
  @override
  void initState() {
    super.initState();
    playerProvider.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    playerProvider.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = playerProvider.currentLyrics;
    final plainLyrics = lyrics?.plainLyrics ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 30),
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.45,
              decoration: const BoxDecoration(
                color: Color(0xff2b8094),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ),
          const Positioned(
            top: 33, left: 15,
            child: Text("Lyrics", style: TextStyle(fontFamily: "AM", fontSize: 18, fontWeight: FontWeight.w600, color: MyColors.whiteColor)),
          ),
          Positioned(
            top: 33, right: 15,
            child: Container(
              height: 28,
              decoration: BoxDecoration(
                color: MyColors.darkGreyColor.withValues(alpha: 0.6),
                borderRadius: const BorderRadius.all(Radius.circular(15)),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      const Text("MORE", style: TextStyle(fontFamily: "AM", fontSize: 10, color: MyColors.whiteColor, fontWeight: FontWeight.w400)),
                      const SizedBox(width: 8),
                      Image.asset("images/icon_bigger_size.png"),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0, right: 15,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 47),
              child: Container(
                height: 25,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Image.asset('images/share.png', height: 10, width: 10),
                        const SizedBox(width: 5),
                        const Text("ShARE", style: TextStyle(fontFamily: "AM", fontSize: 10, color: MyColors.whiteColor, fontWeight: FontWeight.w400)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 30),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.22,
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
                child: Text(
                  plainLyrics.isNotEmpty ? plainLyrics : "No lyrics found",
                  style: TextStyle(
                    color: plainLyrics.isNotEmpty ? MyColors.whiteColor : MyColors.whiteColor.withValues(alpha: 0.5),
                    fontFamily: "AM",
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
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
