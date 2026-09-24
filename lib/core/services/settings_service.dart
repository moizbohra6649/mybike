import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import 'supabase_service.dart';

/// Global (non-showroom-scoped) application settings, backed by `public.settings`.
///
/// The table stores key → JSONB with a nullable `showroom_id`; a NULL row is a
/// global setting, a non-NULL row is a per-branch override. Only the global
/// rows are read and written here — branch overrides belong to the showroom
/// module.
class SettingsService {
  static final SettingsService instance = SettingsService._();

  SettingsService._();

  /// The keys seeded by `supabase/migrations/02_seed_data.sql`, with the same
  /// defaults, so the screen is fully usable before Supabase is connected.
  static const Map<String, Object> defaults = {
    'app_name': 'MYBIKE ERP',
    'currency_code': 'INR',
    'currency_symbol': '₹',
    'default_gst_rate': 18,
    'vehicle_gst_rate': 28,
    'ev_gst_rate': 5,
    'support_email': 'support@mybike.com',
  };

  /// Keys whose value is a number rather than text — the form parses these on
  /// save instead of storing the raw string.
  static const Set<String> numericKeys = {
    'default_gst_rate',
    'vehicle_gst_rate',
    'ev_gst_rate',
  };

  /// Overlay written while running on demo data, so a save survives in-session
  /// even though there is no database behind it.
  static final Map<String, Object> _devOverrides = {};

  bool get _isSupabaseLive =>
      SupabaseConfig.isConfigured && SupabaseService.client != null;

  /// Reads every global setting. Keys without a row fall back to [defaults].
  Future<Map<String, Object>> fetchGlobalSettings() async {
    final values = Map<String, Object>.from(defaults);

    if (!_isSupabaseLive) {
      await SupabaseService.devLatency();
      return values..addAll(_devOverrides);
    }

    try {
      final rows = await SupabaseService.client!
          .from('settings')
          .select('key, value')
          .filter('showroom_id', 'is', null);
      for (final row in (rows as List)) {
        final map = row as Map<String, dynamic>;
        final key = map['key'] as String?;
        final value = map['value'];
        // `value` is NOT NULL, but JSONB 'null' still decodes to a Dart null,
        // and `null as Object` would throw — keep the seeded default instead.
        if (key != null && value != null && values.containsKey(key)) {
          values[key] = value as Object;
        }
      }
    } catch (e) {
      debugPrint('SettingsService: query failed, using defaults: $e');
    }
    return values;
  }

  /// Writes the given global settings.
  ///
  /// Update-then-insert rather than `upsert(onConflict: 'key')`: the unique
  /// index on `(key)` is *partial* (`WHERE showroom_id IS NULL`), and Postgres
  /// cannot infer a partial index from a plain `ON CONFLICT (key)` — it rejects
  /// the statement with "no unique or exclusion constraint matching the ON
  /// CONFLICT specification".
  Future<void> saveGlobalSettings(Map<String, Object> values) async {
    if (!_isSupabaseLive) {
      await SupabaseService.devLatency();
      _devOverrides.addAll(values);
      return;
    }

    final client = SupabaseService.client!;
    final missing = <String>[];

    for (final entry in values.entries) {
      final updated = await client
          .from('settings')
          .update({'value': entry.value})
          .eq('key', entry.key)
          .filter('showroom_id', 'is', null)
          .select('id');
      if ((updated as List).isEmpty) missing.add(entry.key);
    }

    if (missing.isEmpty) return;
    await client.from('settings').insert([
      for (final key in missing)
        {'key': key, 'value': values[key], 'showroom_id': null},
    ]);
  }
}
