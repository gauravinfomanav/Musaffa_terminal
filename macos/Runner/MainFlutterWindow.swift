import Cocoa
import FlutterMacOS
import UserNotifications

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
   
    
    let flutterViewController = FlutterViewController()
    let minSize = NSSize(width: 1400, height: 800)
    self.minSize = minSize
    let initialSize = NSSize(width: 1400, height: 800)
    let initialFrame = NSRect(origin: NSPoint(x: 100, y: 100), size: initialSize)
    self.setFrame(initialFrame, display: true)
    
    self.contentViewController = flutterViewController

    RegisterGeneratedPlugins(registry: flutterViewController)
    
    
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      print("🔍 MainFlutterWindow: Permission request completed - granted: \(granted)")
      if let error = error {
        print("🔍 MainFlutterWindow: Permission error: \(error.localizedDescription)")
      }
      
      if granted {
        print("✅ Notification permission granted")
        // Register for remote notifications AFTER permission is granted
        DispatchQueue.main.async {
          print("🔍 MainFlutterWindow: About to call NSApp.registerForRemoteNotifications()")
          NSApp.registerForRemoteNotifications()
          print("📱 Registered for remote notifications")
        }
      } else {
        print("❌ Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
      }
    }
    
    print("🔍 MainFlutterWindow: About to call super.awakeFromNib()")

    super.awakeFromNib()
    
    print("🔍 MainFlutterWindow: super.awakeFromNib() completed")
  }
  
  // Handle successful APNs registration
  func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("✅ APNs registration successful")
    print("📱 Device token length: \(deviceToken.count) bytes")
    print("📱 Device token: \(deviceToken.map { String(format: "%02x", $0) }.joined())")
    print("🔍 MainFlutterWindow: APNs token received - this should make FCM work!")
  }
  
  // Handle APNs registration failure
  func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
   
    // Check specific error types
    
  }
  
  // Override performClose to intercept Cmd+W
  override func performClose(_ sender: Any?) {
    // Don't close the window, let Flutter handle Cmd+W for watchlist toggle
    // If you want to close the window, call super.performClose(sender)
  }
  
  // Override keyDown to handle Cmd+W before it triggers window closing
  override func keyDown(with event: NSEvent) {
    // Check for Cmd+W
    if event.modifierFlags.contains(.command) && event.keyCode == 13 { // 13 is 'W' key
      // Send the event to Flutter to handle
      self.contentViewController?.keyDown(with: event)
      return
    }
    super.keyDown(with: event)
  }
}
