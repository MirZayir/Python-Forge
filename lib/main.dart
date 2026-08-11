import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serious_python/serious_python.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Application entry point.
void main() {
  runApp(
    const ProviderScope(
      child: PythonForgeApp(),
    ),
  );
}

/// Entry point for the Android process-isolated Python worker.
///
/// This function is invoked by [PythonWorkerService] in the `:python_worker`
/// process. It intentionally owns no UI and remains alive while Serious
/// Python serves the authenticated loopback execution endpoint.
@pragma('vm:entry-point')
Future<void> pythonWorkerMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('python_forge/worker_bootstrap');
  final workerFinished = Completer<void>();

  Future<void> notifyStopped() async {
    try {
      await channel.invokeMethod<void>('stopped');
    } catch (_) {
      // The service may already be terminating the worker process.
    }
  }

  Future<void> startWorker(Object? arguments) async {
    final values = arguments is Map ? arguments : const <Object?, Object?>{};
    final token = values['token'] as String? ?? '';
    final port = values['port'] as String? ?? '8765';
    if (token.trim().isEmpty) {
      if (!workerFinished.isCompleted) {
        workerFinished.completeError(
          StateError('The Python worker received no authentication token.'),
        );
      }
      unawaited(notifyStopped());
      return;
    }

    try {
      await SeriousPython.run(
        'app/app.zip',
        environmentVariables: <String, String>{
          'PYTHON_FORGE_AUTH_TOKEN': token,
          'PYTHON_FORGE_PORT': port,
        },
      );
      if (!workerFinished.isCompleted) workerFinished.complete();
    } catch (error, stackTrace) {
      if (!workerFinished.isCompleted) {
        workerFinished.completeError(error, stackTrace);
      }
    } finally {
      unawaited(notifyStopped());
    }
  }

  channel.setMethodCallHandler((call) async {
    if (call.method == 'configure') {
      unawaited(startWorker(call.arguments));
      return null;
    }
    return null;
  });
  await channel.invokeMethod<void>('ready');
  await workerFinished.future;
}

/// Root application widget.
///
/// The router has one explicit cold-start location: `/`, which renders the
/// home screen. Mission screens are only reachable through an intentional
/// navigation action or a valid typed route extra.
class PythonForgeApp extends ConsumerWidget {
  const PythonForgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Python Forge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.forgeTheme,
      routerConfig: router,
    );
  }
}
