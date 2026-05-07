import 'package:classmate_app_1/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Theme Provider Tests', () {
    test('ThemeProvider initializes with light theme by default', () {
      final provider = ThemeProvider();
      expect(provider.isDarkMode, false);
    });

    test('ThemeProvider provides light theme', () {
      final provider = ThemeProvider();
      final theme = provider.lightTheme;
      expect(theme, isNotNull);
      expect(theme.brightness, Brightness.light);
    });

    test('ThemeProvider provides dark theme', () {
      final provider = ThemeProvider();
      final theme = provider.darkTheme;
      expect(theme, isNotNull);
      expect(theme.brightness, Brightness.dark);
    });

    test('Light theme has Material Design 3 enabled', () {
      final provider = ThemeProvider();
      final theme = provider.lightTheme;
      expect(theme.useMaterial3, true);
    });

    test('Dark theme has Material Design 3 enabled', () {
      final provider = ThemeProvider();
      final theme = provider.darkTheme;
      expect(theme.useMaterial3, true);
    });

    test('Theme colors are consistent', () {
      final provider = ThemeProvider();
      final lightTheme = provider.lightTheme;
      final darkTheme = provider.darkTheme;

      expect(lightTheme, isNotNull);
      expect(darkTheme, isNotNull);
      expect(lightTheme.brightness, Brightness.light);
      expect(darkTheme.brightness, Brightness.dark);
    });
  });
}
