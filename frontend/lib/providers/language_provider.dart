import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  bool isTamil = false;

  String get languageCode => isTamil ? "ta" : "en";

  void toggleLanguage() {
    isTamil = !isTamil;
    notifyListeners();
  }

  String text({required String en, required String ta}) {
    return isTamil ? ta : en;
  }
}
