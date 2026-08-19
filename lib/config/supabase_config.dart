import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static bool isConfigured = false;
  static String supabaseUrl = '';
  static String supabasePublishableKey = '';
  static String? configError;

  // Read environment variables passed via --dart-define or --dart-define-from-file
  static const String _envUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String _envKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: '');

  static Future<void> initialize() async {
    supabaseUrl = _envUrl;
    supabasePublishableKey = _envKey;

    // If not supplied via dart-define, try loading from .env file
    if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
      try {
        await dotenv.load(fileName: ".env");
        if (supabaseUrl.isEmpty) {
          supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
        }
        if (supabasePublishableKey.isEmpty) {
          supabasePublishableKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
              dotenv.env['SUPABASE_ANON_KEY'] ??
              '';
        }
      } catch (e) {
        debugPrint("Info: Kein .env File gefunden oder geladen ($e).");
      }
    }

    final isValidUrl = supabaseUrl.startsWith('https://') &&
        !supabaseUrl.contains('YOUR_SUPABASE_URL') &&
        !supabaseUrl.contains('your-project-id');

    final isValidKey = supabasePublishableKey.length > 20 &&
        !supabasePublishableKey.startsWith('YOUR_SUPABASE_PUBLISHABLE_KEY') &&
        !supabasePublishableKey.startsWith('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...');

    if (isValidUrl && isValidKey) {
      try {
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabasePublishableKey,
          realtimeClientOptions: const RealtimeClientOptions(
            eventsPerSecond: 10,
          ),
        );
        isConfigured = true;
        configError = null;
        debugPrint("Supabase erfolgreich initialisiert: $supabaseUrl");
      } catch (e) {
        isConfigured = false;
        configError = "Fehler bei der Supabase-Initialisierung: $e";
        debugPrint(configError);
      }
    } else {
      isConfigured = false;
      configError = "Supabase-Konfiguration fehlt oder enthält noch Platzhalter.";
      debugPrint("Info: $configError");
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => isConfigured ? Supabase.instance.client.auth.currentUser : null;
  static String? get currentUserId => currentUser?.id;
  static bool get isAuthenticated => currentUser != null;
}
