package com.example.python_forge

import android.app.ActivityManager
import android.content.Intent
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result

class MainActivity : FlutterActivity() {
    private val nativeChannel = "python_forge/native"
    private val workerChannel = "python_forge/worker_control"
    private val mainHandler = Handler(Looper.getMainLooper())
    private val workerProcessName by lazy { "$packageName:python_worker" }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, nativeChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "getNativeMessage") {
                    result.success("Hello from Android!")
                } else {
                    result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, workerChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startPythonWorker" -> {
                        val token = call.argument<String>("token")
                        if (token.isNullOrBlank()) {
                            result.error("INVALID_TOKEN", "A worker token is required.", null)
                            return@setMethodCallHandler
                        }
                        if (isWorkerProcessRunning()) {
                            result.error(
                                "WORKER_ALREADY_RUNNING",
                                "The previous Python worker has not stopped yet.",
                                null,
                            )
                            return@setMethodCallHandler
                        }
                        try {
                            val intent = Intent(this, PythonWorkerService::class.java)
                                .putExtra(PythonWorkerService.EXTRA_TOKEN, token)
                            startService(intent)
                            result.success(null)
                        } catch (error: Throwable) {
                            result.error(
                                "WORKER_START_FAILED",
                                error.message ?: "Unable to start the Python worker.",
                                null,
                            )
                        }
                    }
                    "stopPythonWorker" -> stopPythonWorker(result)
                    "isPythonWorkerRunning" -> result.success(isWorkerProcessRunning())
                    else -> result.notImplemented()
                }
            }
    }

    private fun stopPythonWorker(result: Result) {
        try {
            stopService(Intent(this, PythonWorkerService::class.java))
            awaitWorkerStopped(result, 0)
        } catch (error: Throwable) {
            result.error(
                "WORKER_STOP_FAILED",
                error.message ?: "Unable to stop the Python worker.",
                null,
            )
        }
    }

    private fun awaitWorkerStopped(result: Result, attempt: Int) {
        if (!isWorkerProcessRunning()) {
            result.success(null)
            return
        }
        if (attempt >= 50) {
            result.error(
                "WORKER_STOP_TIMEOUT",
                "The Python worker process did not stop within 5 seconds.",
                null,
            )
            return
        }
        mainHandler.postDelayed({
            awaitWorkerStopped(result, attempt + 1)
        }, 100L)
    }

    private fun isWorkerProcessRunning(): Boolean {
        val activityManager = getSystemService(ACTIVITY_SERVICE) as? ActivityManager
            ?: return false
        return activityManager.runningAppProcesses?.any { process ->
            process.processName == workerProcessName
        } == true
    }
}
