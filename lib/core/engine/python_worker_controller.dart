import 'package:flutter/services.dart';

/// Controls the Android process that owns the embedded Python interpreter.
///
/// The worker is deliberately managed through a narrow platform channel. The
/// UI process never embeds learner code on Android; it only starts, stops, and
/// talks to the worker's authenticated loopback service.
class PythonWorkerController {
  PythonWorkerController({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'python_forge/worker_control';

  final MethodChannel _channel;

  Future<void> start({required String token}) async {
    await _channel.invokeMethod<void>(
      'startPythonWorker',
      <String, Object>{'token': token},
    );
  }

  Future<void> stop() async {
    await _channel.invokeMethod<void>('stopPythonWorker');
  }

  Future<bool> isRunning() async {
    return await _channel.invokeMethod<bool>('isPythonWorkerRunning') ?? false;
  }
}
