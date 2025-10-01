import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Non-UI constants are fine to hardcode per user rule; no user-facing strings here
  static const String supabaseUrl =
      'https://rchoesdfptbveugigfox.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJjaG9lc2RmcHRidmV1Z2lnZm94Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzkwMTEwMDIsImV4cCI6MjA1NDU4NzAwMn0.L1t8Commv15EWsyQGsUzfRhitJDdE4QWZ8boTcfWeMM';

  static bool _initialized = false;

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    if (_initialized) return;
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    _initialized = true;
  }
}


