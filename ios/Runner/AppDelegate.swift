import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // ── Local LLM platform channel ──────────────────────────────────────────
    let controller = window?.rootViewController as! FlutterViewController
    let llmChannel = FlutterMethodChannel(
      name: "com.bodypress/local_llm",
      binaryMessenger: controller.binaryMessenger
    )

    llmChannel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "resolveBackend":
        // TODO: Probe for Core ML / on-device model availability
        result("none")
      case "downloadModel":
        // TODO: Real model download
        result(["modelName": "stub-model-q4"])
      case "activateModel":
        result(nil)
      case "deactivateModel":
        result(nil)
      case "deleteModel":
        result(nil)
      case "chatCompletion":
        // TODO: Route to real on-device inference (Core ML / llama.cpp)
        result(["content": "[iOS local stub] On-device inference not yet wired."])
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
