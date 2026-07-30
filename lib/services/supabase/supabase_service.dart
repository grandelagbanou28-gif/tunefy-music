import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient? _client;

  static SupabaseClient get client => _client ??= _init();

  static SupabaseClient _init() {
    final url = _supabaseUrl();
    final anonKey = _supabaseAnonKey();

    if (_client == null && url.isNotEmpty && anonKey.isNotEmpty) {
      Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
    }

    return Supabase.instance.client;
  }

  static String _supabaseUrl() {
    return const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  }

  static String _supabaseAnonKey() {
    return const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  }

  static bool get isInitialized => _client != null;
}