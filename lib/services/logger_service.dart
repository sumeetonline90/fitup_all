import 'package:logger/logger.dart';

import 'trace_log_service.dart';

/// Central logging — do not use [print] in production code.
abstract final class LoggerService {
  LoggerService._();

  static final Logger _log = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  /// Debug-level (verbose development info).
  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _log.d(message, error: error, stackTrace: stackTrace);
    if (TraceLogService.isEnabled) {
      TraceLogService.appendLog('D', message, error, stackTrace);
    }
  }

  /// Informational.
  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _log.i(message, error: error, stackTrace: stackTrace);
    if (TraceLogService.isEnabled) {
      TraceLogService.appendLog('I', message, error, stackTrace);
    }
  }

  /// Warning.
  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _log.w(message, error: error, stackTrace: stackTrace);
    if (TraceLogService.isEnabled) {
      TraceLogService.appendLog('W', message, error, stackTrace);
    }
  }

  /// Error.
  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _log.e(message, error: error, stackTrace: stackTrace);
    if (TraceLogService.isEnabled) {
      TraceLogService.appendLog('E', message, error, stackTrace);
    }
  }
}
