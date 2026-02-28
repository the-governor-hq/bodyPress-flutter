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
        // iOS is remote-only for now.
        result("none")
      case "downloadModel":
        result(
          FlutterError(
            code: "UNSUPPORTED_ON_IOS",
            message: "Local model download is not supported on iOS. Use remote AI mode.",
            details: nil
          )
        )
      case "activateModel":
        result(
          FlutterError(
            code: "UNSUPPORTED_ON_IOS",
            message: "Local model activation is not supported on iOS. Use remote AI mode.",
            details: nil
          )
        )
      case "deactivateModel":
        result(
          FlutterError(
            code: "UNSUPPORTED_ON_IOS",
            message: "Local model deactivation is not supported on iOS.",
            details: nil
          )
        )
      case "deleteModel":
        result(
          FlutterError(
            code: "UNSUPPORTED_ON_IOS",
            message: "Local model deletion is not supported on iOS.",
            details: nil
          )
        )
      case "chatCompletion":
        result(
          FlutterError(
            code: "UNSUPPORTED_ON_IOS",
            message: "Local chat completion is not supported on iOS. Use remote AI mode.",
            details: nil
          )
        )
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
