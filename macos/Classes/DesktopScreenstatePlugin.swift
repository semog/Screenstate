import Cocoa
import FlutterMacOS
import AppKit

public class DesktopScreenstatePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "screenstate", binaryMessenger: registrar.messenger)
    let instance = DesktopScreenstatePlugin(channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  private let channel: FlutterMethodChannel

  public init(_ channel: FlutterMethodChannel) {
    self.channel = channel
    super.init()
     NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(screenDidSleep), name: NSWorkspace.screensDidSleepNotification, object: nil)
 NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(screenDidWake), name: NSWorkspace.screensDidWakeNotification, object: nil)
    
  }
@objc func screenDidSleep() {
 dispatchApplicationState(active: true)
}

@objc func screenDidWake() {
   dispatchApplicationState(active: false)
}
 
  private func dispatchApplicationState(active: Bool) {
    channel.invokeMethod("onScreenStateChange", arguments: active)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "init" {
      dispatchApplicationState(active: false)
      result(nil)
      return
    }
    result(FlutterMethodNotImplemented)
  }
}
