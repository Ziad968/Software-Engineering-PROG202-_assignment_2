import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration and initialization helper for LSRMS.
class SuperBaseConfiguration {
  SuperBaseConfiguration._();

  static const String projectUrl = 'https://yphysunwomkuofjsyntz.supabase.co';
  static const String anonKey = 'PASTE_YOUR_SUPABASE_ANON_KEY_HERE';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: projectUrl,
      publishableKey: 'sb_publishable_zzsqBnPYSvF1EgiVSPRR4Q_eeU1ZpJs',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}