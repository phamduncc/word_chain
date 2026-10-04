import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class LocalSettingsStore {
  LocalSettingsStore(this._preferences);

  static const String _settingsKey = 'word_chain.app_settings.v1';

  final SharedPreferences _preferences;

  Future<AppSettings> load() async {
    return AppSettings.fromStoredJson(_preferences.getString(_settingsKey));
  }

  Future<void> save(AppSettings settings) async {
    await _preferences.setString(_settingsKey, settings.toStoredJson());
  }
}
