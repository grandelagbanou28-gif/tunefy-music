import 'package:flutter/material.dart';
import 'package:tunefy/theme/tunefy_colors.dart';

class TunefyTheme {
  TunefyTheme._();

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: TunefyColors.black,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    fontFamily: 'AB',
    colorScheme: const ColorScheme.dark(
      primary: TunefyColors.green,
      secondary: TunefyColors.green,
      surface: TunefyColors.surface,
      onSurface: TunefyColors.white,
      onPrimary: TunefyColors.white,
      onSecondary: TunefyColors.white,
      error: Color(0xFFCF6679),
      onError: TunefyColors.white,
    ),
    dividerColor: TunefyColors.divider,
    iconTheme: const IconThemeData(color: TunefyColors.white),
    appBarTheme: const AppBarTheme(
      backgroundColor: TunefyColors.black,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: TunefyColors.white),
      titleTextStyle: TextStyle(
        fontFamily: 'AB',
        fontSize: 22,
        color: TunefyColors.white,
        fontWeight: FontWeight.w700,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: TunefyColors.black,
      selectedItemColor: TunefyColors.white,
      unselectedItemColor: TunefyColors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: TunefyColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerTheme: const DividerThemeData(
      color: TunefyColors.divider,
      thickness: 0.5,
      space: 0.5,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: TunefyColors.darkCard,
      contentTextStyle: const TextStyle(fontFamily: 'AB', color: TunefyColors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: TunefyColors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: TunefyColors.white,
      inactiveTrackColor: TunefyColors.darkGrey,
      thumbColor: TunefyColors.white,
      overlayColor: TunefyColors.white.withValues(alpha: 0.1),
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      trackShape: const RoundedRectSliderTrackShape(),
      trackHeight: 3,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: TunefyColors.green,
      linearTrackColor: TunefyColors.darkCard,
    ),
  );
}

class TunefyText {
  TunefyText._();

  static const _font = 'AB';
  static const _fontMedium = 'AM';

  static TextStyle h1({Color color = TunefyColors.white}) => TextStyle(
    fontFamily: _font, fontSize: 28, fontWeight: FontWeight.w800, color: color,
  );

  static TextStyle h2({Color color = TunefyColors.white}) => TextStyle(
    fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w700, color: color,
  );

  static TextStyle h3({Color color = TunefyColors.white}) => TextStyle(
    fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w700, color: color,
  );

  static TextStyle title({Color color = TunefyColors.white}) => TextStyle(
    fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w600, color: color,
  );

  static TextStyle body({Color color = TunefyColors.white}) => TextStyle(
    fontFamily: _fontMedium, fontSize: 14, color: color,
  );

  static TextStyle caption({Color color = TunefyColors.grey}) => TextStyle(
    fontFamily: _fontMedium, fontSize: 12, color: color,
  );

  static TextStyle small({Color color = TunefyColors.grey}) => TextStyle(
    fontFamily: _fontMedium, fontSize: 11, color: color,
  );

  static TextStyle button({Color color = TunefyColors.white}) => TextStyle(
    fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w600, color: color,
  );

  static TextStyle miniPlayer({Color color = TunefyColors.white}) => TextStyle(
    fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w600, color: color,
  );

  static TextStyle miniPlayerSub({Color color = TunefyColors.grey}) => TextStyle(
    fontFamily: _fontMedium, fontSize: 11, color: color,
  );
}

class TunefyAnimations {
  TunefyAnimations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration pageTransition = Duration(milliseconds: 300);

  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve springCurve = Curves.elasticOut;
  static const Curve decelerate = Curves.decelerate;

  static RoutePageBuilder slideUp({Widget? page, Widget Function(BuildContext)? builder}) {
    return (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
      final child = page ?? builder!(context);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      );
    };
  }

  static RoutePageBuilder fadeIn({Widget? page, Widget Function(BuildContext)? builder}) {
    return (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
      final child = page ?? builder!(context);
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
        child: child,
      );
    };
  }

  static RoutePageBuilder scaleFade({Widget? page, Widget Function(BuildContext)? builder}) {
    return (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
      final child = page ?? builder!(context);
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    };
  }
}

Route<T> tunefyRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: TunefyAnimations.pageTransition,
    reverseTransitionDuration: TunefyAnimations.pageTransition,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
    },
  );
}

Route<T> tunefySlideUpRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: TunefyAnimations.pageTransition,
    reverseTransitionDuration: TunefyAnimations.pageTransition,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}
