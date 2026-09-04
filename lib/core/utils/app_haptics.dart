import 'package:flutter/services.dart';

/// Utilidades de retroalimentación háptica (vibración táctil)
class AppHaptics {
  AppHaptics._();

  /// Vibración suave para selecciones de menú, tabs o filtros
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Vibración ligera para toques de botones o elementos interactivos
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  /// Vibración media para confirmar cambios de estado o guardado
  static void success() {
    HapticFeedback.mediumImpact();
  }

  /// Vibración pesada para acciones críticas (ej. eliminar registros)
  static void warning() {
    HapticFeedback.heavyImpact();
  }
}
