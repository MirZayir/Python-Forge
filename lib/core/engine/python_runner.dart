import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:serious_python/serious_python.dart';

import 'execution_result.dart';

/// Abstract contract for Python code execution backends.
abstract class PythonRunner {
  Future<ExecutionResult> run(String code);
}

/// Embedded CPython runner backed by the bundled Serious Python service.
///
/// The bundled program blocks inside `serve_forever()`, so the future returned
/// by [SeriousPython.run] intentionally never completes while the engine is
/// healthy. Readiness is therefore established by polling the local service,
/// and a completed future means the program exited early, which is a failure.
class SeriousPythonRunner implements PythonRunner {
  static const String assetPath = 'app/app.zip';
  static const Duration _readinessTimeout = Duration(seconds: 25);
  static const Duration _requestTimeout = Duration(seconds: 8);
  static final Uri _serverUri = Uri.parse('http://127.0.0.1:8765/');

  static final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 5)
    ..idleTimeout = const Duration(seconds: 10);

  static bool _launched = false;
  static bool _isReady = false;
  static Object? _startupError;
  static String? _programExitMessage;
  static Future<void>? _readiness;

  @override
  Future<ExecutionResult> run(String code) async {
    final stopwatch = Stopwatch()..start();
    try {
      await _ensureReady();
      final data = await _postJson({'code': code}, timeout: _requestTimeout);

      final output = data['output'];
      if (output is! String) {
        throw const FormatException(
          'The Python service returned a malformed response.',
        );
      }

      final hasErrorValue = data['has_error'];
      if (hasErrorValue is! bool) {
        throw const FormatException(
          'The Python service returned an invalid error flag.',
        );
      }
      final rawErrorType = data['error_type'];
      final errorType = rawErrorType is String && rawErrorType.trim().isNotEmpty
          ? rawErrorType
          : null;
      return ExecutionResult(
        output: output,
        success: !hasErrorValue,
        executionTimeMs: stopwatch.elapsedMilliseconds,
        hasError: hasErrorValue,
        errorType: errorType,
        truncated: data['truncated'] == true,
      );
    } on TimeoutException {
      return ExecutionResult(
        output:
            'Execution timed out after ${_requestTimeout.inSeconds}s. Check for an infinite loop.',
        success: false,
        executionTimeMs: stopwatch.elapsedMilliseconds,
        hasError: true,
        errorType: 'TimeoutError',
      );
    } catch (error) {
      return ExecutionResult(
        output: 'Python engine failure: ${_describe(error)}',
        success: false,
        executionTimeMs: stopwatch.elapsedMilliseconds,
        hasError: true,
      );
    } finally {
      stopwatch.stop();
    }
  }

  static String _describe(Object error) {
    final detail = _programExitMessage;
    if (detail != null && detail.trim().isNotEmpty) {
      return '$error (python: ${detail.trim()})';
    }
    return '$error';
  }

  static Future<void> _ensureReady() {
    if (_isReady) return Future<void>.value();

    final existing = _readiness;
    if (existing != null) return existing;

    final future = _waitForReady();
    _readiness = future;
    future.then<void>(
      (_) {
        if (identical(_readiness, future)) _readiness = null;
      },
      onError: (Object error, StackTrace stackTrace) {
        // Allow a later attempt to retry readiness polling after startup or
        // health-check failure without retaining a failed future forever.
        if (identical(_readiness, future)) _readiness = null;
      },
    );
    return future;
  }

  static Future<void> _waitForReady() async {
    _launch();

    final deadline = DateTime.now().add(_readinessTimeout);
    Object? lastError;

    while (DateTime.now().isBefore(deadline)) {
      try {
        final data = await _postJson(
          const {'code': ''},
          timeout: const Duration(seconds: 3),
        );
        if (data['has_error'] == false) {
          _isReady = true;
          return;
        }
        lastError = StateError('Health check reported an execution error.');
      } catch (error) {
        lastError = error;
      }

      final startupError = _startupError;
      if (startupError != null) {
        throw StateError(
          'Unable to start the embedded Python service: $startupError',
        );
      }

      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    throw StateError(
      'The embedded Python service did not become ready: ${_describe(lastError ?? 'unknown error')}',
    );
  }

  /// Starts the interpreter exactly once for the process lifetime.
  static void _launch() {
    if (_launched) return;
    _startupError = null;
    _programExitMessage = null;
    _launched = true;

    SeriousPython.run(assetPath).then((message) {
      // Completing means the Python program stopped serving. Serious Python
      // returns Python errors as a string instead of throwing, so record it
      // and permit a later execution attempt to retry startup.
      _programExitMessage = (message == null || message.trim().isEmpty)
          ? 'The Python program exited without starting the execution service.'
          : message;
      _isReady = false;
      _launched = false;
    }).catchError((Object error) {
      _startupError = error;
      _launched = false;
    });
  }

  static Future<Map<String, dynamic>> _postJson(
    Map<String, String> payload, {
    required Duration timeout,
  }) async {
    HttpClientRequest? request;
    try {
      request = await _client.postUrl(_serverUri).timeout(timeout);
      request.headers.contentType = ContentType.json;

      // An explicit Content-Length is required: without it Dart streams the
      // body with chunked transfer encoding, which the embedded service would
      // read as zero bytes and silently execute empty code.
      final body = utf8.encode(jsonEncode(payload));
      request.contentLength = body.length;
      request.add(body);

      final response = await request.close().timeout(timeout);
      final responseBody =
          await response.transform(utf8.decoder).join().timeout(timeout);

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'The Python service returned HTTP ${response.statusCode}.',
          uri: _serverUri,
        );
      }

      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
            'The Python service returned invalid JSON.');
      }
      return decoded;
    } catch (_) {
      request?.abort();
      rethrow;
    }
  }
}

/// Backward-compatible name used by existing screens.
typedef LocalPythonInterpreter = SeriousPythonRunner;
