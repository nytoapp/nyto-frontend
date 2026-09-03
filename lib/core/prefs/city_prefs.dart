import 'package:shared_preferences/shared_preferences.dart';

/// Launch location prefs — city fixed to Hyderabad; area is user-editable.
class LocationPrefs {
  LocationPrefs._();

  static const cityKey = 'nyto_city_name';
  static const areaKey = 'nyto_area_name';
  static const gpsAskedKey = 'nyto_gps_asked';

  static const launchCity = 'Hyderabad';
  static const allAreas = 'ALL';

  static Future<String> loadCity() async {
    final prefs = await SharedPreferences.getInstance();
    // Migrate / force launch city for V1.
    await prefs.setString(cityKey, launchCity);
    return launchCity;
  }

  static Future<String> loadArea() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(areaKey)?.trim();
    if (raw == null || raw.isEmpty) return allAreas;
    return raw;
  }

  static Future<void> saveArea(String area) async {
    final prefs = await SharedPreferences.getInstance();
    final value = area.trim().isEmpty ? allAreas : area.trim();
    await prefs.setString(areaKey, value);
    await prefs.setString(cityKey, launchCity);
  }

  static Future<bool> hasAskedGps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(gpsAskedKey) ?? false;
  }

  static Future<void> markGpsAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(gpsAskedKey, true);
  }

  static String headerLabel(String area) {
    if (area == allAreas || area.isEmpty) return launchCity;
    return '$launchCity · $area';
  }

  static String profileSubtitle(String area) {
    if (area == allAreas || area.isEmpty) {
      return '$launchCity · All areas';
    }
    return '$launchCity · $area';
  }
}

/// @Deprecated — use [LocationPrefs]. Kept so older imports compile briefly.
class CityPrefs {
  CityPrefs._();
  static const key = LocationPrefs.cityKey;
  static const defaultCity = LocationPrefs.launchCity;

  static Future<String> load() => LocationPrefs.loadCity();

  static Future<void> save(String cityOrLabel) async {
    // V1 ignores other cities; keep area if present after comma misuse.
    await LocationPrefs.loadCity();
  }

  static String displayLabel(String cityName) =>
      LocationPrefs.profileSubtitle(LocationPrefs.allAreas);
}
