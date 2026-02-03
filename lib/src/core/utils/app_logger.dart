import 'package:logger/logger.dart';

/// Servicio centralizado de logging
///
/// Proporciona un logger configurado globalmente para toda la aplicación.
/// Usa el paquete 'logger' para logs más profesionales que simples prints.
class AppLogger {
  AppLogger._();

  /// Logger global de la aplicación
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, // Número de métodos en el stack trace
      errorMethodCount: 5, // Stack trace más largo para errores
      lineLength: 80, // Ancho de línea
      colors: true, // Colores en consola
      printEmojis: true, // Emojis para cada nivel
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart, // Timestamp
    ),
  );

  /// Logger para producción (más simple, sin colores)
  static final Logger _productionLogger = Logger(
    printer: SimplePrinter(colors: false),
  );

  /// Obtiene el logger apropiado según el entorno
  static Logger get instance {
    // En producción, usa logger simple
    // En desarrollo, usa logger con formato bonito
    const bool isProduction = bool.fromEnvironment('dart.vm.product');
    return isProduction ? _productionLogger : _logger;
  }

  // ===================================
  // MÉTODOS DE CONVENIENCIA
  // ===================================

  /// Log de depuración (development only)
  static void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    instance.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log informativo
  static void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    instance.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log de advertencia
  static void warning(
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    instance.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log de error
  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    instance.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log de error fatal
  static void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    instance.f(message, error: error, stackTrace: stackTrace);
  }
}
