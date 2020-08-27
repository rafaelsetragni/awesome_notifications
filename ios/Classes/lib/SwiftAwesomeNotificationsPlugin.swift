import Flutter
import UIKit

public class SwiftAwesomeNotificationsPlugin: NSObject, FlutterPlugin {
  

  private static func checkGooglePlayServices(){
    return true
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: Definitions.CHANNEL_FLUTTER_PLUGIN, binaryMessenger: registrar.messenger())
    let instance = SwiftAwesomeNotificationsPlugin()

    instance.initializeFlutterPlugin(channel)
  }

  private static func initializeFlutterPlugin(channel: channel) {
    registrar.addMethodCallDelegate(self, channel: channel)    
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
