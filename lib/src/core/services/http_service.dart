import 'package:dio/dio.dart';
import '../utils/app_logger.dart';

/// Servicio HTTP base usando Dio
///
/// Proporciona un cliente HTTP configurado con timeouts,
/// logging y manejo de errores centralizado.
class HttpService {
  static final HttpService _instance = HttpService._internal();
  factory HttpService() => _instance;
  HttpService._internal();

  late final Dio _dio;

  /// Inicializa el servicio HTTP
  void initialize({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? '',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Agregar interceptor para logging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.debug('[HTTP] ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.debug(
            '[HTTP] ${response.statusCode} ${response.requestOptions.uri}',
          );
          return handler.next(response);
        },
        onError: (error, handler) {
          AppLogger.error(
            '[HTTP] Error ${error.response?.statusCode} ${error.requestOptions.uri}',
            error,
          );
          return handler.next(error);
        },
      ),
    );
  }

  /// Realiza una petición GET
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Realiza una petición POST
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Maneja errores de Dio
  void _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        AppLogger.error('Timeout en la petición HTTP', error);
        break;
      case DioExceptionType.badResponse:
        AppLogger.error(
          'Error ${error.response?.statusCode}: ${error.response?.statusMessage}',
          error,
        );
        break;
      case DioExceptionType.cancel:
        AppLogger.warning('Petición HTTP cancelada');
        break;
      case DioExceptionType.connectionError:
        AppLogger.error('Error de conexión', error);
        break;
      case DioExceptionType.badCertificate:
        AppLogger.error('Certificado SSL inválido', error);
        break;
      case DioExceptionType.unknown:
        AppLogger.error('Error desconocido en HTTP', error);
        break;
    }
  }

  /// Cliente Dio para acceso directo si es necesario
  Dio get client => _dio;
}
