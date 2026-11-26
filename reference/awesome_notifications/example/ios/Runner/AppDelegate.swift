import UIKit
import Flutter
import awesome_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      // Kept here (still runs before the engine under UIScene) so background
      // isolates can re-register the awesome_notifications plugin.
      SwiftAwesomeNotificationsPlugin.setPluginRegistrantCallback { registry in
          SwiftAwesomeNotificationsPlugin.register(
            with: registry.registrar(forPlugin: "io.flutter.plugins.awesomenotifications.AwesomeNotificationsPlugin")!)
      }
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // UIScene lifecycle: the implicit engine's plugins are registered here
  // instead of in didFinishLaunchingWithOptions.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
      GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

// Declared here (not in a separate file) so it is picked up by the existing
// Runner target without editing the Xcode project. Referenced from Info.plist
// as $(PRODUCT_MODULE_NAME).SceneDelegate.
class SceneDelegate: FlutterSceneDelegate {
}
