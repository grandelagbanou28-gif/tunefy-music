import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tunefy/DI/service_locator.dart';
import 'package:tunefy/cache/hive_cache.dart';
import 'package:tunefy/services/premium_service.dart';
import 'package:tunefy/services/database_service.dart';
import 'package:tunefy/theme/tunefy_colors.dart';
import 'package:tunefy/tunefy_app.dart' as standalone;

const _supabaseUrl = 'https://uwjpkenrldtexlciaqdz.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV3anBrZW5ybGR0ZXhsY2lhcWR6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUzNjMwMDQsImV4cCI6MjEwMDkzOTAwNH0.k6JMQsMkq4c0ez4l8E71HaqQss_hCnfS38B7LlhP6f0';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('cache');
  await Hive.openBox('settings');
  await Hive.openBox('liked_songs');
  await DbService.init();
  await HiveCache.init();
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
