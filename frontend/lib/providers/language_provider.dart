import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('id'); // Default Bahasa Indonesia

  Locale get locale => _locale;

  LanguageProvider() {
    _loadLanguage();
  }

  // Load bahasa yang tersimpan
  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'id';
    _locale = Locale(languageCode);
    notifyListeners();
  }

  // Ubah bahasa
  Future<void> changeLanguage(String languageCode) async {
    if (_locale.languageCode == languageCode) return;

    _locale = Locale(languageCode);
    
    // Simpan pilihan bahasa
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
    
    notifyListeners();
  }

  // Get language name
  String getLanguageName() {
    return _locale.languageCode == 'en' ? 'English' : 'Bahasa Indonesia';
  }
}