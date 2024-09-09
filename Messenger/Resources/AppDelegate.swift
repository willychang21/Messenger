import UIKit
import Firebase
import FirebaseMessaging
import FacebookCore
import GoogleSignIn
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate {

    let gcmMessageIDKey = "gcm.message_id"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // [START set_messaging_delegate]
        Messaging.messaging().delegate = self
        // [END set_messaging_delegate]
        
        FirebaseApp.configure()
        
        if let user = Auth.auth().currentUser {
            print("You are sign in as \(user.uid) email:\(String(describing: user.email))")
        }
        
        // [START register_for_notifications]
        // Override point for customization after application launch.
        UNUserNotificationCenter.current().delegate = self
        // request consent from the user to deliver notification
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            guard success else {
                print("error: \(String(describing: error))")
                return
            }
            print("Success in APNS registry")
        }
        UIApplication.shared.registerForRemoteNotifications()
        // [END register_for_notifications]
        
        // MARK: Facebook login
        // Facebook
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        
        // MARK: Google Sign in
        // Google Sign in : Attempt to restore the user's sign-in state
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if error != nil || user == nil {
                // Show the app's signed-out state.
            } else {
                // Show the app's signed-in state.
            }
        }
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    // MARK: FCM Support
    // register to get the token
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        messaging.token { token, error in
            guard let token = token else {
                print("Error fetching FCM registration token: \(String(describing: error))")
                return
            }
            print("FCM registration token: \(token)")
        }
    }
    
    // Access Token :
    // Device Token : recognize device
    
    // MARK: APNS Support
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        let token = deviceToken.reduce("") {
            $0 + String(format: "%02x", $1)
        }
        print("APNS Token: \(token)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("didFailToRegisterForRemoteNotififcationWithError: \(error)")
    }
    
    // background notification
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    // MARK: Facebook Login
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        
        // Handle Google URL types
        var handled: Bool
        
        handled = GIDSignIn.sharedInstance.handle(url)
        if handled {
            return true
        }
        
        // Handle Facebook URL types
        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
        
        // If not handled by this app, return false.
        return false
    }

}

// MARK: Notification
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // App is suspended in background, and user click notification in NotificationCenter. (iOS12 or before)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print(#function)
        let content = response.notification.request.content
        // ...
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)

        // Print full message.
        print(content.userInfo)
        completionHandler()
    }
    
    // APP is runnigng in foreground and receive a remote notification.
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo

        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)

        // ...

        // Print full message.
        print(userInfo)
        
        // Change this to your preferred presentation option
        completionHandler([[.sound, .banner,]])
    }
}
/// because when user delete app an reinstall app will create a new token, to avoid bug, update new bug when open app
//extension AppDelegate: MessagingDelegate {
//  // [START refresh_token]
//  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
//    print("Firebase registration token: \(String(describing: fcmToken))")
//
//    let dataDict: [String: String] = ["token": fcmToken ?? ""]
//    NotificationCenter.default.post(
//      name: Notification.Name("FCMToken"),
//      object: nil,
//      userInfo: dataDict
//    )
//    // TODO: If necessary send token to application server.
//    // Note: This callback is fired at each app startup and whenever a new token is generated.
//  }
//
//  // [END refresh_token]
//}
