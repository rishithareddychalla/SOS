import UIKit
import Flutter
import flutter_phone_call_state

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    private let CHANNEL = "com.example.sos_app/conference_call" // Ensure this matches Flutter

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let callChannel = FlutterMethodChannel(name: CHANNEL,
                                                      binaryMessenger: controller.binaryMessenger)
        callChannel.setMethodCallHandler({
          (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
          guard call.method == "startConferenceCall" else { // The method name is kept for consistency
            result(FlutterMethodNotImplemented)
            return
          }
            // By the time we get here, the new package will handle the logic.
            // This native handler can be simplified or removed if all logic moves to Dart.
            // For now, we leave it to ensure the channel is open.
            // The actual sequential dialing will be managed in Dart using the new package's stream.
            // We will just initiate the first call from here as a fallback or initial trigger.
            if let args = call.arguments as? [String: Any],
               let numbers = args["numbers"] as? [String],
               let firstNumber = numbers.first {
                self.initiateCall(number: firstNumber)
            }
            result("Initiation signal received by iOS.")
        })

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func initiateCall(number: String) {
        let urlString = "tel://\(number)"
        if let url = URL(string: urlString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }

    // --- Background Monitoring Setup for flutter_phone_call_state ---

    func initBackground(){
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier)
        })
    }

    override func applicationWillEnterForeground(_ application: UIApplication) {
        super.applicationWillEnterForeground(application)
        // When the app comes to the foreground, re-initialize the plugin's state
        FlutterPhoneCallStatePlugin.shared.initState()
    }

    override func applicationDidEnterBackground(_ application: UIApplication) {
        super.applicationDidEnterBackground(application)
        // When the app goes to the background, start the background monitoring task
        // The package documentation recommends calling this *before* the app enters background,
        // so we will also call it from the Dart side before initiating the call sequence.
        // This is a fallback.
        initBackground()
        FlutterPhoneCallStatePlugin.shared.beginBackgroundMonitoring()
    }
}
