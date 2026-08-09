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
  static const Duration _requestTimeout = Duration(seconds: 20);
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

      final hasError = data['has_error'] == true;
      return ExecutionResult(
        output: output,
        success: !hasError,
        executionTimeMs: stopwatch.elapsedMilliseconds,
        hasError: hasError,
      );
    } on TimeoutException {
      return ExecutionResult(
        output:
            'Execution timed out after ${_requestTimeout.inSeconds}s. Check for an infinite loop.',
        success: false,
        executionTimeMs: stopwatch.elapsedMilliseconds,
        hasError: true,
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
    return _readiness ??= _waitForReady()
      ..then<void>((_) {}, onError: (_, __) {
        // Allow a later attempt to retry readiness polling.
        _readiness = null;
      });
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
    _launched = true;

    SeriousPython.run(assetPath).then((message) {
      // Completing means the Python program stopped serving. Serious Python
      // returns Python errors as a string instead of throwing, so record it.
      _programExitMessage = (message == null || message.trim().isEmpty)
          ? 'The Python program exited without starting the execution service.'
          : message;
      _isReady = false;
    }).catchError((Object error) {
      _startupError = error;
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
