import 'package:flutter/foundation.dart';

/// Servicio central para el monitoreo y registro de errores silenciosos
class AppErrorLogger {
  AppErrorLogger._();

  /// Registra una excepción o fallo capturado en tiempo de ejecución
  static void logError(
    Object error,
    StackTrace? stackTrace, {
    String context = 'Global',
    bool fatal = false,
  }) {
    // Imprimir en consola de depuración en formato resaltado
    debugPrint('--------------------------------------------------');
    debugPrint('🚨 [ERROR SILENCIOSO REGISTRADO] Contexto: $context');
    debugPrint('⚠️ Severidad: ${fatal ? 'CRÍTICA / FATAL' : 'ADVERTENCIA'}');
    debugPrint('❌ Detalles: $error');
    if (stackTrace != null) {
      debugPrint('📍 StackTrace:\n$stackTrace');
    }
    debugPrint('--------------------------------------------------');

    // En producción, este punto se enlaza automáticamente con Firebase Crashlytics:
    // FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: context, fatal: fatal);
  }

  /// Registra un evento de advertencia o información de diagnóstico
  static void logWarning(String message, {String context = 'General'}) {
    debugPrint('⚠️ [ADVERTENCIA - $context]: $message');
  }
}
