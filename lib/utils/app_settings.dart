import 'package:flutter/material.dart';

class AppSettings extends ChangeNotifier {
String theme = 'light';
double textSize = 1.0;

bool debugMode = false;
bool backendConnected = false;

void setTheme(String newTheme) {
theme = newTheme;
notifyListeners();
}

void setTextSize(double size) {
textSize = size;
notifyListeners();
}

void setDebugMode(bool value) {
debugMode = value;
notifyListeners();
}

void setBackendStatus(bool status) {
backendConnected = status;
notifyListeners();
}
}