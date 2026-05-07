import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _prefKey = 'selectedLanguageCode';

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey) ?? 'en';
    _locale = _normalizeCode(code);
    notifyListeners();
  }

  Future<void> setLocaleByLanguageName(String languageName) async {
    final code = _languageNameToCode(languageName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);
    _locale = _normalizeCode(code);
    notifyListeners();
  }

  String codeToLanguageName() {
    switch (_locale.languageCode) {
      case 'zh':
        return 'Chinese (Mandarin)';
      case 'es':
        return 'Spanish';
      case 'hi':
        return 'Hindi';
      case 'en':
      default:
        return 'English';
    }
  }

  String _languageNameToCode(String languageName) {
    switch (languageName.toLowerCase()) {
      case 'chinese (mandarin)':
      case 'mandarin chinese':
      case 'mandarin':
      case 'chinese':
        return 'zh';
      case 'spanish':
        return 'es';
      case 'hindi':
        return 'hi';
      case 'english':
      default:
        return 'en';
    }
  }

  Locale _normalizeCode(String code) {
    switch (code) {
      case 'zh':
        return const Locale('zh');
      case 'es':
        return const Locale('es');
      case 'hi':
        return const Locale('hi');
      case 'en':
      default:
        return const Locale('en');
    }
  }
}

class LanguageInherited extends InheritedNotifier<LanguageProvider> {
  const LanguageInherited({
    super.key,
    required LanguageProvider languageProvider,
    required super.child,
  }) : super(notifier: languageProvider);

  static LanguageProvider of(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<LanguageInherited>();
    assert(inherited != null, 'No LanguageInherited found in context');
    return inherited!.notifier!;
  }
}
