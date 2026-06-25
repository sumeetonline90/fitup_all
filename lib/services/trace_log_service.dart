import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// On-device diagnostic log for field testing without USB (GPS, activity, errors).
///
/// **Off by default** — no file I/O or string work until the user enables
/// logging in Settings → Field diagnostics. [LoggerService] only forwards here
/// when [isEnabled] is true.
///
/// Files live under app documents: `fitup_trace/fitup_trace.log` (rotates to
/// `fitup_trace.old.log` when large).
abstract final class TraceLogService {
  TraceLogService._();

  static const String _prefEnabled = 'trace_file_logging_enabled';
  static const String _prefIncludeGps = 'trace_include_gps_in_log';

  static const int _maxBufferChars = 16000;
  static const int _maxFileBytes = 4 * 1024 * 1024;
  static const int _maxStackChars = 2500;

  static bool _initialized = false;
  static bool _enabled = false;
  static bool _includeGps = true;
  static Directory? _dir;
  static final List<String> _buffer = <String>[];
  static int _bufferChars = 0;
  static bool _flushing = false;
  static DateTime? _lastGpsSample;

  static bool get isEnabled => _enabled;
  static bool get includeGpsInLog => _includeGps;

  /// Loads prefs only — no filesystem I/O unless logging was left on last session.
  ///
  /// Call after [WidgetsFlutterBinding.ensureInitialized] (mobile/desktop only).
  static Future<void> init() async {
    if (kIsWeb || _initialized) {
      return;
    }
    _initialized = true;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_prefEnabled) ?? false;
      _includeGps = prefs.getBool(_prefIncludeGps) ?? true;
      if (_enabled) {
        await _ensureDirectory();
        await _writeSessionHeader();
      }
    } catch (e, st) {
      debugPrint('TraceLogService.init failed: $e $st');
    }
  }

  static Future<void> _ensureDirectory() async {
    if (_dir != null) {
      return;
    }
    final Directory base = await getApplicationDocumentsDirectory();
    _dir = Directory(p.join(base.path, 'fitup_trace'));
    await _dir!.create(recursive: true);
  }

  static Future<void> setEnabled(bool value) async {
    if (kIsWeb) {
      return;
    }
    await init();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabled, value);
    _enabled = value;
    if (value) {
      await _ensureDirectory();
      await _writeSessionHeader();
    } else {
      await flush();
      _buffer.clear();
      _bufferChars = 0;
      _lastGpsSample = null;
    }
  }

  static Future<void> setIncludeGps(bool value) async {
    if (kIsWeb) {
      return;
    }
    await init();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefIncludeGps, value);
    _includeGps = value;
  }

  static Future<void> _writeSessionHeader() async {
    if (_dir == null) {
      return;
    }
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      final String line =
          '--- Trace start ${DateTime.now().toIso8601String()} '
          '${info.appName} ${info.version}+${info.buildNumber} '
          '${Platform.operatingSystem} ---';
      _addLine(line);
      await flush();
    } catch (e) {
      _addLine('--- Trace start (no package info): $e ---');
      await flush();
    }
  }

  /// Mirror of [LoggerService] lines (no ANSI / colors).
  ///
  /// [LoggerService] only calls this when [isEnabled] is true.
  static void appendLog(
    String level,
    Object? message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (!_enabled || kIsWeb) {
      return;
    }
    final String ts = DateTime.now().toIso8601String();
    final StringBuffer sb = StringBuffer('[$ts] $level ${message ?? ''}');
    if (error != null) {
      sb.write(' | $error');
    }
    if (stackTrace != null) {
      String s = stackTrace.toString();
      if (s.length > _maxStackChars) {
        s = '${s.substring(0, _maxStackChars)}…(truncated)';
      }
      sb.write(' | $s');
    }
    _addLine(sb.toString());
  }

  /// Throttled GPS line while activity tracking (main isolate).
  static void appendGpsSample({
    required double lat,
    required double lng,
    required double accuracyM,
    required double speedMps,
  }) {
    if (!_enabled || !_includeGps || kIsWeb) {
      return;
    }
    final DateTime now = DateTime.now();
    if (_lastGpsSample != null &&
        now.difference(_lastGpsSample!) < const Duration(seconds: 4)) {
      return;
    }
    _lastGpsSample = now;
    _addLine(
      '[${now.toIso8601String()}] GPS '
      'lat=$lat lng=$lng acc=${accuracyM.toStringAsFixed(1)}m '
      'speed=${speedMps.toStringAsFixed(2)}m/s',
    );
  }

  static void _addLine(String line) {
    _buffer.add(line);
    _bufferChars += line.length + 1;
    if (_bufferChars >= _maxBufferChars) {
      unawaited(flush());
    }
  }

  /// Flush buffered lines to disk (call on app pause / background).
  static Future<void> flush() async {
    if (kIsWeb || !_enabled || _dir == null || _buffer.isEmpty || _flushing) {
      return;
    }
    _flushing = true;
    try {
      final File mainFile = File(p.join(_dir!.path, 'fitup_trace.log'));
      final IOSink sink = mainFile.openWrite(
        mode: FileMode.append,
        encoding: utf8,
      );
      try {
        for (final String line in _buffer) {
          sink.writeln(line);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      _buffer.clear();
      _bufferChars = 0;
      await _rotateIfNeeded(mainFile);
    } catch (e) {
      debugPrint('TraceLogService.flush failed: $e');
    } finally {
      _flushing = false;
    }
  }

  static Future<void> _rotateIfNeeded(File mainFile) async {
    try {
      final int len = await mainFile.length();
      if (len <= _maxFileBytes) {
        return;
      }
      final File old = File(p.join(_dir!.path, 'fitup_trace.old.log'));
      if (await old.exists()) {
        await old.delete();
      }
      await mainFile.rename(old.path);
    } catch (e) {
      debugPrint('TraceLogService._rotateIfNeeded: $e');
    }
  }

  /// Primary log path for display / export.
  static String? get primaryLogPath {
    if (_dir == null) {
      return null;
    }
    return p.join(_dir!.path, 'fitup_trace.log');
  }

  static Future<List<XFile>> exportableFiles() async {
    if (_dir == null) {
      return <XFile>[];
    }
    await flush();
    final List<XFile> out = <XFile>[];
    final File main = File(p.join(_dir!.path, 'fitup_trace.log'));
    final File old = File(p.join(_dir!.path, 'fitup_trace.old.log'));
    if (await main.exists() && await main.length() > 0) {
      out.add(XFile(main.path));
    }
    if (await old.exists() && await old.length() > 0) {
      out.add(XFile(old.path));
    }
    return out;
  }

  static Future<void> shareLogs() async {
    final List<XFile> files = await exportableFiles();
    if (files.isEmpty) {
      return;
    }
    await Share.shareXFiles(
      files,
      text: 'Fitup field trace',
    );
  }

  static Future<void> clearAll() async {
    if (_dir == null) {
      return;
    }
    await flush();
    try {
      await for (final FileSystemEntity e in _dir!.list()) {
        if (e is File) {
          await e.delete();
        }
      }
    } catch (e) {
      debugPrint('TraceLogService.clearAll: $e');
    }
    if (_enabled) {
      await _writeSessionHeader();
    }
  }
}
