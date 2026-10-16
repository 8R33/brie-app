import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BriePalette {
  final String name;
  final bool isDark;
  final Map<String, Color> colors;

  const BriePalette({
    required this.name,
    required this.isDark,
    required this.colors,
  });

  Color get background => colors['background']!;
  Color get surface => colors['surface']!;
  Color get card => colors['card']!;
  Color get accent => colors['accent']!;
  Color get text => colors['text']!;
  Color get muted => colors['muted']!;

  BriePalette copyWithColor(String key, Color color) {
    return BriePalette(
      name: name,
      isDark: isDark,
      colors: {...colors, key: color},
    );
  }

  ThemeData toThemeData() {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: isDark ? Brightness.dark : Brightness.light,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Georgia',
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: card,
      colorScheme: scheme.copyWith(
        primary: accent,
        surface: surface,
        onSurface: text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      textTheme: ThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        fontFamily: 'Georgia',
      ).textTheme.apply(bodyColor: text, displayColor: text),
    );
  }
}

class BrieThemeController extends ChangeNotifier {
  BrieThemeController._();

  static final BrieThemeController instance = BrieThemeController._();

  static const String light = 'Light';
  static const String purple = 'Tranquil Purple';
  static const String blue = 'Ocean Blue';

  static const Map<String, Color> _lightDefaults = {
    'background': Color(0xFFFFF4F7),
    'surface': Color(0xFFFFFFFF),
    'card': Color(0xFFFFE9EF),
    'accent': Color(0xFFC75D83),
    'text': Color(0xFF5A4050),
    'muted': Color(0xFF9C8A92),
  };

  static const Map<String, Color> _purpleDefaults = {
    'background': Color(0xFF190933),
    'surface': Color(0xFF4B3F6E),
    'card': Color(0xFF35204F),
    'accent': Color(0xFFBA96C1),
    'text': Color(0xFFE8E5D1),
    'muted': Color(0xFFC5B5CE),
  };

  static const Map<String, Color> _blueDefaults = {
    'background': Color(0xFF04222B),
    'surface': Color(0xFF0A3D4A),
    'card': Color(0xFF06313D),
    'accent': Color(0xFF69DDE0),
    'text': Color(0xFFE2F4F0),
    'muted': Color(0xFF4FB8B4),
  };

  String _selectedTheme = light;
  final Map<String, BriePalette> _palettes = {};

  String get selectedTheme => _selectedTheme;

  List<String> get themeNames => const [light, purple, blue];

  BriePalette get currentPalette => _palettes[_selectedTheme]!;

  BriePalette paletteFor(String name) => _palettes[name]!;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();

    _selectedTheme = preferences.getString('brie_selected_theme') ?? light;

    _palettes[light] = _loadPalette(preferences, light, _lightDefaults, false);
    _palettes[purple] = _loadPalette(
      preferences,
      purple,
      _purpleDefaults,
      true,
    );
    _palettes[blue] = _loadPalette(preferences, blue, _blueDefaults, true);

    if (!_palettes.containsKey(_selectedTheme)) {
      _selectedTheme = light;
    }
  }

  BriePalette _loadPalette(
    SharedPreferences preferences,
    String name,
    Map<String, Color> defaults,
    bool isDark,
  ) {
    final saved = preferences.getString('brie_palette_$name');
    final colors = <String, Color>{...defaults};

    if (saved != null) {
      try {
        final decoded = jsonDecode(saved) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          final value = int.tryParse(entry.value.toString());
          if (value != null && defaults.containsKey(entry.key)) {
            colors[entry.key] = Color(value);
          }
        }
      } catch (_) {
        // Use the official palette if saved data is invalid.
      }
    }

    return BriePalette(name: name, isDark: isDark, colors: colors);
  }

  Future<void> selectTheme(String name) async {
    if (!_palettes.containsKey(name)) return;

    _selectedTheme = name;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('brie_selected_theme', name);
  }

  Future<void> updateColor(String key, Color color) async {
    final palette = currentPalette;
    if (!palette.colors.containsKey(key)) return;

    _palettes[_selectedTheme] = palette.copyWithColor(key, color);
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    final savedColors = _palettes[_selectedTheme]!.colors.map(
      (key, value) => MapEntry(key, value.toARGB32()),
    );

    await preferences.setString(
      'brie_palette_$_selectedTheme',
      jsonEncode(savedColors),
    );
  }

  Future<void> resetCurrentPalette() async {
    final defaults = switch (_selectedTheme) {
      purple => _purpleDefaults,
      blue => _blueDefaults,
      _ => _lightDefaults,
    };

    final isDark = _selectedTheme != light;

    _palettes[_selectedTheme] = BriePalette(
      name: _selectedTheme,
      isDark: isDark,
      colors: {...defaults},
    );

    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('brie_palette_$_selectedTheme');

    notifyListeners();
  }
}
