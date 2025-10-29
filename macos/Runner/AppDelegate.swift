import Cocoa
import FlutterMacOS
import UserNotifications

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    
   
    // Check entitlements
    if let entitlements = Bundle.main.object(forInfoDictionaryKey: "com.apple.security.application-groups") {
      print("🔍 AppDelegate: Entitlements found: \(entitlements)")
    } else {
      print("🔍 AppDelegate: No entitlements found in Info.plist")
    }
    
    // Request notification permissions
    print("🔍 AppDelegate: Requesting notification permissions...")
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      print("🔍 AppDelegate: Permission request completed - granted: \(granted)")
      if let error = error {
        print("🔍 AppDelegate: Permission error: \(error.localizedDescription)")
      }
      
      if granted {
        print("✅ Notification permission granted")
        // Register for remote notifications AFTER permission is granted
        DispatchQueue.main.async {
          print("🔍 AppDelegate: About to call NSApp.registerForRemoteNotifications()")
          NSApp.registerForRemoteNotifications()
          print("📱 Registered for remote notifications")
        }
      } else {
        print("❌ Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
      }
    }
    
    // Set notification delegate
    UNUserNotificationCenter.current().delegate = self
    print("🔍 AppDelegate: Notification delegate set")
  }
  
  // Handle successful APNs registration
  override func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    
  }
  
  // Handle APNs registration failure
  override func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
   
    
   
  }
  
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
  // Handle notifications when app is in foreground
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    print("📨 Received notification in foreground: \(notification.request.content.title)")
    completionHandler([.alert, .badge, .sound])
  }
  
  // Handle notification tap
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    print("📨 Notification tapped: \(response.notification.request.content.title)")
    completionHandler()
  }
}
