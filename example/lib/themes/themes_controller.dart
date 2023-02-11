import 'package:flutter/material.dart';

import '../main_complete.dart';

enum Themes { Light, Dark }

class ThemesController {
  static final appThemeData = {
    Themes.Light: ThemeData(
      brightness: Brightness.light,

      primaryColor: App.mainColor,
      // ignore: deprecated_member_use
      accentColor: Colors.blueGrey,
      canvasColor: Colors.white,
      focusColor: Colors.blueAccent,
      disabledColor: Colors.grey,

      backgroundColor: Colors.blueGrey.shade400,

      appBarTheme: AppBarTheme(
        // ignore: deprecated_member_use
        brightness: Brightness.dark,
        color: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: App.mainColor,
        ),
      ),
    ),
  };

  static ThemeData? _currentTheme;

  ThemesController(bool isLight) {
    _currentTheme = appThemeData[isLight ? Themes.Light : Themes.Dark]!;
  }

  /// Use this method on UI to get selected theme.
  static ThemeData get currentTheme {
    if (_currentTheme == null) {
      _currentTheme = appThemeData[Themes.Light];
    }
    return _currentTheme!;
  }

  /// Sets theme and notifies listeners about change.
  setTheme(Themes theme) async {
    _currentTheme = appThemeData[theme];

    // Here we notify listeners that theme changed
    // so UI have to be rebuild
    // notifyListeners();
  }
}
