import Cocoa
import FlutterMacOS
import AppKit
import Cocoa
import CoreGraphics 
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
     NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(screenDidSleep), name: NSWorkspace.willSleepNotification, object: nil)
 NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(screenDidWake), name: NSWorkspace.didWakeNotification, object: nil)
  let center = DistributedNotificationCenter.default()
        center.addObserver(self, selector: #selector(screenIsLocked), name: NSNotification.Name(rawValue: "com.apple.screenIsLocked"), object: nil)
        center.addObserver(self, selector: #selector(screenIsUnlocked), name: NSNotification.Name(rawValue: "com.apple.screenIsUnlocked"), object: nil)

  }

@objc func screenIsLocked() {
       dispatchApplicationState(active: "locked")
    }
    
    @objc func screenIsUnlocked() {
       dispatchApplicationState(active: "unlocked")
    }
@objc func screenDidSleep() {
 dispatchApplicationState(active: "sleep")
}

@objc func screenDidWake() {
   dispatchApplicationState(active: "awaked")
}
 
  private func dispatchApplicationState(active: String) {
    channel.invokeMethod("onScreenStateChange", arguments: active)
  }

}
