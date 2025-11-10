import 'dart:developer' as developer;
import 'dart:io';
import 'dart:async';
import 'dart:math';

/// Tipos de errores que puede encontrar la aplicación
enum ErrorType {
  networkError,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  serverError,
  databaseError,
  unknown,
}

/// Clase centralizada para manejar, categorizar y logear errores
class AppErrorHandler {
  static const String _logName = 'AppErrorHandler';

  /// Categoriza un error en un tipo específico para manejo consistente
  static ErrorType categorizeError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Errores de red
    if (error is SocketException) {
      return ErrorType.networkError;
    }
    if (error is TimeoutException) {
      return ErrorType.timeout;
    }
    if (errorString.contains('socket') ||
        errorString.contains('connection refused') ||
        errorString.contains('network') ||
        errorString.contains('unreachable')) {
      return ErrorType.networkError;
    }

    // Errores HTTP por código
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return ErrorType.unauthorized;
    }
    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return ErrorType.forbidden;
    }
    if (errorString.contains('404') || errorString.contains('not found')) {
      return ErrorType.notFound;
    }
    if (errorString.contains('500') ||
        errorString.contains('server error') ||
        errorString.contains('bad gateway')) {
      return ErrorType.serverError;
    }

    // Errores de base de datos
    if (errorString.contains('sql') ||
        errorString.contains('database') ||
        errorString.contains('constraint')) {
      return ErrorType.databaseError;
    }

    return ErrorType.unknown;
  }

  /// Retorna un mensaje amigable para mostrar al usuario
  static String getUserMessage(ErrorType type) {
    switch (type) {
      case ErrorType.networkError:
        return 'No hay conexión. Verifica tu WiFi o datos móviles.';
      case ErrorType.timeout:
        return 'Conexión lenta. Reintentando...';
      case ErrorType.unauthorized:
        return 'Tu sesión expiró. Por favor, inicia sesión nuevamente.';
      case ErrorType.forbidden:
        return 'No tienes permiso para acceder a esto.';
      case ErrorType.notFound:
        return 'No se encontró lo que buscabas.';
      case ErrorType.serverError:
        return 'El servidor está teniendo problemas. Intenta en unos momentos.';
      case ErrorType.databaseError:
        return 'Error al acceder a los datos. Intenta de nuevo.';
      case ErrorType.unknown:
        return 'Algo salió mal. Intenta de nuevo.';
    }
  }

  /// Determina si el error es recuperable (se puede reintentar)
  static bool isRetryable(ErrorType type) {
    return type == ErrorType.networkError ||
        type == ErrorType.timeout ||
        type == ErrorType.serverError;
  }

  /// Logea un error con contexto completo (error, stack trace, contexto)
  static void logError(dynamic error, StackTrace stack, {String? context}) {
    final errorType = categorizeError(error);
    final message = '''
╔══════════════════════════════════════════════════════════════
║ ERROR: ${errorType.toString().split('.').last.toUpperCase()}
║ Context: ${context ?? 'No context'}
║ Message: ${error.toString()}
╚══════════════════════════════════════════════════════════════
''';

    developer.log(
      message,
      error: error,
      stackTrace: stack,
      name: _logName,
      level: 1000, // SEVERE level
    );
  }

  /// Retorna un mensaje más técnico para debugging (solo en debug mode)
  static String getDebugMessage(dynamic error) {
    return error.toString();
  }
}

/// Clase auxiliar para manejar reintentos con backoff exponencial
class RetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration timeout;

  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.timeout = const Duration(seconds: 15),
  });

  /// Calcula el tiempo de espera para un reintento específico
  Duration getDelayForAttempt(int attemptNumber) {
    final multiplier = pow(backoffMultiplier, (attemptNumber - 1).toDouble());
    return Duration(
      milliseconds: (initialDelay.inMilliseconds * multiplier).toInt(),
    );
  }
}

/// Ejecuta una operación con reintentos automáticos y timeout
Future<T> executeWithRetry<T>(
  Future<T> Function() operation, {
  RetryConfig config = const RetryConfig(),
  String? operationName,
}) async {
  int attempt = 0;

  while (attempt < config.maxRetries) {
    attempt++;
    try {
      // Ejecutar con timeout
      final result = await operation().timeout(
        config.timeout,
        onTimeout:
            () =>
                throw TimeoutException(
                  'Operation ${operationName ?? 'unknown'} timed out after ${config.timeout.inSeconds}s',
                ),
      );
      return result;
    } catch (e, stack) {
      final errorType = AppErrorHandler.categorizeError(e);
      final isRetryable = AppErrorHandler.isRetryable(errorType);
      final isLastAttempt = attempt >= config.maxRetries;

      if (isRetryable && !isLastAttempt) {
        final delayDuration = config.getDelayForAttempt(attempt);
        developer.log(
          'Attempt $attempt/$config.maxRetries failed. '
          'Retrying in ${delayDuration.inSeconds}s... '
          'Error: $e',
          name: 'RetryHandler',
        );
        await Future.delayed(delayDuration);
      } else {
        // No se puede reintentar o es el último intento
        AppErrorHandler.logError(
          e,
          stack,
          context:
              'executeWithRetry - $operationName (attempt $attempt/${config.maxRetries})',
        );
        rethrow;
      }
    }
  }

  throw Exception('Max retries exceeded for operation: $operationName');
}
