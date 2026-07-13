import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccentThemeColors {
  final Color primary;
  final Color secondary;
  final Color accent;
  final String displayName;

  const AccentThemeColors({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.displayName,
  });
}

class ThemeProvider with ChangeNotifier {
  static const Map<String, AccentThemeColors> accentThemes = {
    'indigo': AccentThemeColors(
      displayName: 'Indigo Cyan',
      primary: Color(0xFF6366F1),
      secondary: Color(0xFF06B6D4),
      accent: Color(0xFFEC4899),
    ),
    'sunset': AccentThemeColors(
      displayName: 'Sunset Orange',
      primary: Color(0xFFF97316),
      secondary: Color(0xFFEF4444),
      accent: Color(0xFFF59E0B),
    ),
    'emerald': AccentThemeColors(
      displayName: 'Emerald Wave',
      primary: Color(0xFF10B981),
      secondary: Color(0xFF06B6D4),
      accent: Color(0xFF3B82F6),
    ),
    'royal': AccentThemeColors(
      displayName: 'Royal Purple',
      primary: Color(0xFF8B5CF6),
      secondary: Color(0xFFD946EF),
      accent: Color(0xFFF43F5E),
    ),
  };

  ThemeMode _themeMode = ThemeMode.system;
  String _accentColorName = 'indigo';

  ThemeMode get themeMode => _themeMode;
  String get accentColorName => _accentColorName;

  Color get primaryColor => accentThemes[_accentColorName]?.primary ?? accentThemes['indigo']!.primary;
  Color get secondaryColor => accentThemes[_accentColorName]?.secondary ?? accentThemes['indigo']!.secondary;
  Color get accentColor => accentThemes[_accentColorName]?.accent ?? accentThemes['indigo']!.accent;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final themeStr = prefs.getString('theme_mode');
      if (themeStr == 'light') {
        _themeMode = ThemeMode.light;
      } else if (themeStr == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }

      _accentColorName = prefs.getString('accent_color_name') ?? 'indigo';
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme from prefs: $e');
    }
  }

  Future<void> updateAccentColor(String name) async {
    if (!accentThemes.containsKey(name)) return;
    _accentColorName = name;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accent_color_name', name);
    } catch (e) {
      debugPrint('Error saving accent color: $e');
    }
  }

  Future<void> toggleTheme() async {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'theme_mode',
        _themeMode == ThemeMode.light ? 'light' : 'dark',
      );
    } catch (e) {
      debugPrint('Error saving theme to prefs: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', mode.toString().split('.').last);
    } catch (e) {
      debugPrint('Error saving theme to prefs: $e');
    }
  }
}
