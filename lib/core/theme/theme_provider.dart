import 'package:flutter/material.dart';
import '../../data/local/theme_local_datasource.dart';

class ThemeProvider extends ChangeNotifier {
  final ThemeLocalDataSource _localDataSource = ThemeLocalDataSource();
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> loadFromPrefs() async {
    final modeString = await _localDataSource.getThemeMode();
    if (modeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == modeString,
        orElse: () => ThemeMode.light,
      );
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    await _localDataSource.saveThemeMode(_themeMode.name);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
      await _localDataSource.saveThemeMode(mode.name);
    }
  }
}
