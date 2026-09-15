package com.captionary.captionary

import android.app.ActivityManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val memoryChannel = "com.captionary.captionary/system_memory"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, memoryChannel).setMethodCallHandler { call, result ->
            if (call.method == "getMemoryInfo") {
                try {
                    val actManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                    val memInfo = ActivityManager.MemoryInfo()
                    actManager.getMemoryInfo(memInfo)

                    val data = mapOf(
                        "totalMem" to memInfo.totalMem,
                        "availMem" to memInfo.availMem,
                        "lowMemory" to memInfo.lowMemory,
                        "threshold" to memInfo.threshold
                    )
                    result.success(data)
                } catch (e: Exception) {
                    result.error("MEMORY_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
