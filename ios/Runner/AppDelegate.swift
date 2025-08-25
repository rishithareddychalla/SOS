// import Flutter
// import UIKit

// @main
// @objc class AppDelegate: FlutterAppDelegate {
//   override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   ) -> Bool {
//     GeneratedPluginRegistrant.register(with: self)
//     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   }
// }
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private let CHANNEL = "com.example.sos_app/conference_call"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let conferenceCallChannel = FlutterMethodChannel(name: CHANNEL,
                                                  binaryMessenger: controller.binaryMessenger)
    conferenceCallChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      guard call.method == "startConferenceCall" else {
        result(FlutterMethodNotImplemented)
        return
      }
      if let args = call.arguments as? [String: Any],
         let numbers = args["numbers"] as? [String] {
        self.initiateCalls(numbers: numbers)
        result("Calls initiated")
      } else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Phone number list cannot be null or empty.", details: nil))
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func initiateCalls(numbers: [String]) {
    for (index, number) in numbers.enumerated() {
      // Add a delay before initiating subsequent calls to allow the user to interact with the call UI.
      DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(index * 8)) {
        let urlString = "telprompt://\(number)"
        if let url = URL(string: urlString) {
          if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
          }
        }
      }
    }
  }
}