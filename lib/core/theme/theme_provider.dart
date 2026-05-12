import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  SharedPreferences? _prefs;

  FirebaseAuth? get _auth => Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null;
  FirebaseFirestore? get _firestore => Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _initTheme();
  }

  Future<void> _initTheme() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('Error loading theme preferences: $e');
      _isDarkMode = false;
      notifyListeners();
      return;
    }

    // First, try to load from Firestore (server source of truth)
    final auth = _auth;
    final user = auth?.currentUser;
    if (user != null) {
      try {
        final firestore = _firestore;
        if (firestore == null) {
          throw StateError('Firebase is not initialized');
        }

        final doc = await firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final themePreference = doc.data()?['isDarkMode'];
          if (themePreference is bool) {
            _isDarkMode = themePreference;
            // Update local SharedPreferences to match Firestore
            await _prefs?.setBool('isDarkMode', _isDarkMode);
            notifyListeners();
            return;
          }
        }
      } catch (e) {
        debugPrint('Error loading theme from Firestore: $e');
      }
    }

    // Fallback to local SharedPreferences
    _isDarkMode = _prefs?.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Save theme preference to both local storage and Firestore
  Future<void> _saveThemePreference(bool isDarkMode) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setBool('isDarkMode', isDarkMode);

      // Also save to Firestore for cross-device persistence
      final auth = _auth;
      final firestore = _firestore;
      final user = auth?.currentUser;
      if (user != null) {
        if (firestore == null) {
          return;
        }

        await firestore.collection('users').doc(user.uid).set({
          'isDarkMode': isDarkMode,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _saveThemePreference(_isDarkMode);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _saveThemePreference(_isDarkMode);
    notifyListeners();
  }

  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        secondary: const Color(0xFFE1BEE7),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        secondary: const Color(0xFFE1BEE7),
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
