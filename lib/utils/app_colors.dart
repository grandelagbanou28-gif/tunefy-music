import 'package:flutter/material.dart';

class AppColors {
  // Text Colors
  static const Color primaryText = Colors.white;
  static const Color secondaryText = Color(0xFFB3B3B3); // Grey[400] approx
  static const Color tertiaryText = Color(0xFF757575); // Grey[600] approx

  // UI Colors
  static const Color primaryAccent = Colors.white;
  static const Color error = Colors.redAccent;

  // Backgrounds
  static const Color scaffoldDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF181818);

  // Light transparent black — the "glass" card surface used across the app
  // (About artist, Lyrics, menus, tiles, etc). Pair with cardBorder so cards
  // stay distinguishable from the black background.
  static const Color cardTranslucent = Color(0x8C000000);

  // Fine light border that separates a translucent card from the background.
  static const Color cardBorder = Color(0x1FFFFFFF);
}
