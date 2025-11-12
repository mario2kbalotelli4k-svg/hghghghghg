import 'package:flutter/material.dart';

class AppLanguage extends ChangeNotifier {
  String _languageCode = 'en'; // اللغة الافتراضية هي الإنجليزية

  String get languageCode => _languageCode;

  void changeLanguage(String newLanguageCode) {
    _languageCode = newLanguageCode;
    notifyListeners(); // تحديث جميع الواجهات التي تعتمد على اللغة
  }
}