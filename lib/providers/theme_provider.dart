import 'package:flutter/material.dart';

/// Guarda las preferencias visuales del usuario (personalización de la UI).
class ThemeProvider extends ChangeNotifier {
  Color _seed = Colors.indigo;
  bool _dark = false;

  Color get seed => _seed;
  bool get isDark => _dark;

  /// Cambia el color principal de la app.
  void setColor(Color color) {
    if (_seed == color) return;
    _seed = color;
    notifyListeners(); // Reconstruye los widgets que escuchan este provider
  }

  /// Alterna entre modo claro y oscuro.
  void toggleDark() {
    _dark = !_dark;
    notifyListeners();
  }
}
