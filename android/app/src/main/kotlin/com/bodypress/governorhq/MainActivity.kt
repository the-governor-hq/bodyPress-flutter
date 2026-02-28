package com.bodypress.governorhq

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.bodypress/local_llm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "resolveBackend" -> {
                        // TODO: Probe for ML Kit / MediaPipe availability
                        // For now return "none" until a real backend is integrated.
                        result.success("none")
                    }
                    "downloadModel" -> {
                        // TODO: Implement real model download (HuggingFace / bundled asset).
                        result.success(mapOf("modelName" to "stub-model-q4"))
                    }
                    "activateModel" -> {
                        // TODO: Load model into runtime memory.
                        result.success(null)
                    }
                    "deactivateModel" -> {
                        result.success(null)
                    }
                    "deleteModel" -> {
                        result.success(null)
                    }
                    "chatCompletion" -> {
                        // TODO: Route to real on-device inference.
                        result.success(mapOf("content" to "[Android local stub] On-device inference not yet wired."))
                    }
                    else -> result.notImplemented()
                }
            }
    }
}