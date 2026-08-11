import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:serious_python/serious_python.dart';

import 'execution_result.dart';
import 'python_worker_controller.dart';

/// Abstract contract for Python code execution backends.
abstract class PythonRunner {
  Future<ExecutionResult> run(String code);
}

/// Serious Python runner with platform-aware worker supervision.
///
/// Android runs the embedded interpreter in an application-owned
/// `:python_worker` process. The UI process supervises the authenticated
/// loopback service and stops the worker process after a request timeout. Other
/// platforms retain the embedded Serious Python fallback and therefore remain
/// constrained execution, not a killable security sandbox.
class SeriousPythonRunner implements PythonRunner {
  static const String assetPath = 'app/app.zip';
  static const String runtimeManifestAssetPath = 'app/runtime_manifest.json';
  static const Duration _readinessTimeout = Duration(seconds: 25);
  static const Duration _requestTimeout = Duration(seconds: 8);
  static const String _workerTokenHeader = 'X-Python-Forge-Token';
  static final Uri _serverUri = Uri.parse('http://127.0.0.1:8765/');

  static HttpClient? _httpClient;
  static final PythonWorkerController _workerController =
      PythonWorkerController();
  static final bool _usesProcessWorker = !kIsWeb && Platform.isAndroid;

  static bool _launched = false;
  static bool _isReady = false;
  static Object? _startupError;
  static String? _programExitMessage;
  static Future<void>? _readiness;
  static Future<void>? _assetVerification;
  static bool _runtimeAssetsVerified = false;
  static String? _workerToken;
  static Future<bool>? _workerStop;
  static Object? _workerStopError;

  static HttpClient get _client => _httpClient ??= HttpClient()
    ..connectionTimeout = const Duration(seconds: 5)
    ..idleTimeout = const Duration(seconds: 10);

  @override
  Future<ExecutionResult> run(String code) async {
    final stopwatch = Stopwatch()..start();
    if (kIsWeb) {
      stopwatch.stop();
      return const ExecutionResult(
        output:
            'Python execution is not available in the web build. Use the Android worker or a supported native platform.',
        success: false,
        executionTimeMs: 0,
        hasError: true,
        errorType: 'UnsupportedError',
      );
    }

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
      final stopped = await _stopProcessWorker();
      return ExecutionResult(
        output: _usesProcessWorker
            ? stopped
                ? 'Execution timed out after ${_requestTimeout.inSeconds}s. The Python worker was terminated; try again.'
                : 'Execution timed out after ${_requestTimeout.inSeconds}s, but worker termination could not be confirmed. Restart the app before trying again.'
            : 'Execution timed out after ${_requestTimeout.inSeconds}s. Check for an infinite loop.',
        success: false,
        executionTimeMs: stopwatch.elapsedMilliseconds,
        hasError: true,
        errorType: 'TimeoutError',
      );
    } catch (error) {
      await _stopProcessWorker();
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
    final existing = _readiness;
    if (existing != null) return existing;

    final future = _ensureReadyInternal();
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

  static Future<void> _ensureReadyInternal() async {
    if (_isReady) {
      if (!_usesProcessWorker || await _workerController.isRunning()) {
        return;
      }
      // The Android process can die without completing the worker bootstrap
      // callback. Reconcile the cached Dart state before the next request.
      _isReady = false;
    }
    await _waitForReady();
  }

  static Future<void> _waitForReady() async {
    await _verifyRuntimeAssets();
    await _launch();

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
          'Unable to start the Python worker: $startupError',
        );
      }

      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    throw StateError(
      'The Python worker did not become ready: ${_describe(lastError ?? 'unknown error')}',
    );
  }

  static Future<void> _launch() async {
    if (_usesProcessWorker) {
      final stopping = _workerStop;
      if (stopping != null) await stopping;
      if (_workerStopError != null) {
        final recovered = await _stopProcessWorker();
        if (!recovered) {
          throw StateError(
            'The previous Python worker could not be stopped safely.',
          );
        }
      }

      final workerRunning = await _workerController.isRunning();
      if (_launched && workerRunning) return;
      if (workerRunning || _launched) {
        final recovered = await _stopProcessWorker();
        if (!recovered) {
          throw StateError(
            'The previous Python worker could not be stopped safely.',
          );
        }
      }
    }

    if (_launched) return;
    _startupError = null;
    _programExitMessage = null;
    _workerToken = _newWorkerToken();
    _launched = true;

    if (_usesProcessWorker) {
      try {
        await _workerController.start(token: _workerToken!);
      } catch (error) {
        _startupError = error;
        _launched = false;
        rethrow;
      }
      return;
    }

    // Non-Android platforms still use the package's embedded runtime. This
    // branch intentionally remains classified as constrained execution.
    unawaited(
      SeriousPython.run(
        assetPath,
        environmentVariables: <String, String>{
          'PYTHON_FORGE_AUTH_TOKEN': _workerToken!,
          'PYTHON_FORGE_PORT': '8765',
        },
      ).then<void>(
        (message) {
          // Completing means the Python program stopped serving. Serious
          // Python returns Python errors as a string instead of throwing, so
          // record it and permit a later execution attempt to retry startup.
          _programExitMessage = (message == null || message.trim().isEmpty)
              ? 'The Python program exited without starting the execution service.'
              : message;
          _isReady = false;
          _launched = false;
        },
        onError: (Object error, StackTrace stackTrace) {
          _startupError = error;
          _launched = false;
        },
      ),
    );
  }

  static Future<bool> _stopProcessWorker() async {
    _isReady = false;
    if (!_usesProcessWorker) {
      // serious_python.terminate() is a no-op on the current fallback
      // platforms. Do not reset _launched and accidentally start a second
      // embedded interpreter on the same fixed port.
      return false;
    }

    final existing = _workerStop;
    if (existing != null) return existing;

    final future = _stopAndResetProcessWorker();
    _workerStop = future;
    try {
      return await future;
    } finally {
      if (identical(_workerStop, future)) _workerStop = null;
    }
  }

  static Future<bool> _stopAndResetProcessWorker() async {
    try {
      await _workerController.stop();
    } catch (error) {
      _workerStopError = error;
      return false;
    }

    _workerStopError = null;
    _launched = false;
    _startupError = null;
    _programExitMessage = null;
    _workerToken = null;
    _readiness = null;
    return true;
  }

  static String _newWorkerToken() {
    final random = Random.secure();
    return List<String>.generate(
      32,
      (_) => random.nextInt(16).toRadixString(16),
      growable: false,
    ).join();
  }

  static Future<void> _verifyRuntimeAssets() {
    if (_runtimeAssetsVerified) return Future<void>.value();

    final existing = _assetVerification;
    if (existing != null) return existing;

    final future = _loadAndVerifyRuntimeAssets();
    _assetVerification = future;
    future.then<void>(
      (_) {
        if (identical(_assetVerification, future)) {
          _runtimeAssetsVerified = true;
          _assetVerification = null;
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (identical(_assetVerification, future)) _assetVerification = null;
      },
    );
    return future;
  }

  static Future<void> _loadAndVerifyRuntimeAssets() async {
    final rawManifest = await rootBundle.loadString(runtimeManifestAssetPath);
    final decoded = jsonDecode(rawManifest);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('The Python runtime manifest is malformed.');
    }

    final manifestVersion = decoded['manifest_version'];
    final sourcePath = decoded['source_path'];
    final sourceHash = decoded['source_sha256'];
    final archivePath = decoded['archive_path'];
    final expectedArchiveHash = decoded['archive_sha256'];
    if (manifestVersion != 1 ||
        sourcePath != 'python_src/main.py' ||
        archivePath != assetPath ||
        !_isSha256(sourceHash) ||
        !_isSha256(expectedArchiveHash)) {
      throw const FormatException(
        'The Python runtime manifest has an invalid schema or hash.',
      );
    }

    final archive = await rootBundle.load(assetPath);
    final bytes = archive.buffer.asUint8List(
      archive.offsetInBytes,
      archive.lengthInBytes,
    );
    final actualArchiveHash = sha256.convert(bytes).toString();
    if (actualArchiveHash != expectedArchiveHash) {
      throw StateError(
        'The packaged Python runtime hash does not match its manifest.',
      );
    }
  }

  static bool _isSha256(Object? value) {
    return value is String && RegExp(r'^[0-9a-f]{64}$').hasMatch(value);
  }

  static Future<Map<String, dynamic>> _postJson(
    Map<String, String> payload, {
    required Duration timeout,
  }) async {
    HttpClientRequest? request;
    final deadline = Stopwatch()..start();

    Future<T> withRemaining<T>(Future<T> future) {
      final remaining = timeout - deadline.elapsed;
      if (remaining.isNegative || remaining == Duration.zero) {
        return Future<T>.error(
          TimeoutException('The Python request exceeded its deadline.'),
        );
      }
      return future.timeout(remaining);
    }

    try {
      final openedRequest = await withRemaining(
        _client.postUrl(_serverUri),
      );
      request = openedRequest;
      openedRequest.headers.contentType = ContentType.json;
      final token = _workerToken;
      if (token != null && token.isNotEmpty) {
        openedRequest.headers.set(_workerTokenHeader, token);
      }

      // An explicit Content-Length is required: without it Dart streams the
      // body with chunked transfer encoding, which the embedded service would
      // read as zero bytes and silently execute empty code.
      final body = utf8.encode(jsonEncode(payload));
      openedRequest.contentLength = body.length;
      openedRequest.add(body);

      final response = await withRemaining(openedRequest.close());
      final responseBody = await withRemaining(
        response.transform(utf8.decoder).join(),
      );

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
    } finally {
      deadline.stop();
    }
  }
}

/// Backward-compatible name used by existing screens.
typedef LocalPythonInterpreter = SeriousPythonRunner;
