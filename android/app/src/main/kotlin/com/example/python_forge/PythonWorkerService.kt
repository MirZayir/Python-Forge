package com.example.python_forge

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.os.Process
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

/**
 * Owns the embedded Python interpreter in a separate Android process.
 *
 * The service intentionally uses a killable process boundary instead of
 * relying on Dart cancellation or Python tracing to interrupt native code.
 * The supervisor process stops this service after a timeout; onDestroy then
 * terminates this process so a wedged interpreter cannot retain the app.
 */
class PythonWorkerService : Service() {
    companion object {
        const val EXTRA_TOKEN = "python_forge_worker_token"
        private const val WORKER_ENTRYPOINT = "pythonWorkerMain"
        private const val WORKER_PORT = "8765"
    }

    private var flutterEngine: FlutterEngine? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val token = intent?.getStringExtra(EXTRA_TOKEN)
        if (token.isNullOrBlank()) {
            stopSelf(startId)
            return START_NOT_STICKY
        }

        if (flutterEngine == null) {
            startFlutterWorker(token)
        }
        return START_NOT_STICKY
    }

    private fun startFlutterWorker(token: String) {
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(applicationContext)
        loader.ensureInitializationComplete(applicationContext, null)

        val engine = FlutterEngine(applicationContext)
        GeneratedPluginRegistrant.registerWith(engine)
        val workerChannel = MethodChannel(
            engine.dartExecutor.binaryMessenger,
            "python_forge/worker_bootstrap",
        )
        workerChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "ready" -> {
                    result.success(null)
                    workerChannel.invokeMethod(
                        "configure",
                        mapOf("token" to token, "port" to WORKER_PORT),
                    )
                }
                "stopped" -> {
                    result.success(null)
                    stopSelf()
                }
                else -> result.notImplemented()
            }
        }
        val entrypoint = DartExecutor.DartEntrypoint(
            loader.findAppBundlePath(),
            WORKER_ENTRYPOINT,
        )
        engine.dartExecutor.executeDartEntrypoint(entrypoint)
        flutterEngine = engine
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        // Do not attempt to tear down an embedded interpreter cooperatively:
        // that operation is not a kill boundary and can itself hang. The OS
        // reclaims the complete worker process immediately after this callback.
        flutterEngine = null
        super.onDestroy()
        Process.killProcess(Process.myPid())
    }
}
