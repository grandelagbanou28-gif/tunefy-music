import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tunefy/DI/service_locator.dart';
import 'package:tunefy/services/premium_service.dart';
import 'package:tunefy/services/database_service.dart';
import 'package:tunefy/theme/tunefy_colors.dart';
import 'package:tunefy/tunefy_app.dart' as standalone;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('cache');
  await Hive.openBox('settings');
  await Hive.openBox('liked_songs');
  await DbService.init();
  initServiceLocator();
  PremiumService.load();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: TunefyColors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const standalone.TunefyApp());
}
