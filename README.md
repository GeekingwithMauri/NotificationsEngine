# NotificationsEngine

## Rationale

Ideally, we want to have our code completely dependency-free and preserve control over its entire functioning. In the real world, we know this is unrealistic since it would imply reinventing the wheel over and over. 

_NotificationsEngine_ centralizes the notifications SDKs and exposes them via facades.

## What's the point?
Contracts expire, SDKs get deprecated and fees rises. These, just to mention a few, are valid reasons to change tracking vendors. 

This is rather hard when our codebases are littered with direct SDKs implementations. _NotificationsEngine_ makes such processes painless by making their consumption behind a facade. This is why, whatever happens under the hood shall not concern our Tracking clients apps.

## Installation 
### Xcode 13
 1. From the **File** menu, **Add Packages…**.
 2. Enter package repository URL: `https://github.com/GeekingwithMauri/NotificationsEngine`
 3. Confirm the version and let Xcode resolve the package

### Swift Package Manager

If you want to use _NotificationsEngine_ in any other project that uses [SwiftPM](https://swift.org/package-manager/), add the package as a dependency in `Package.swift`:

```swift
dependencies: [
  .package(
    url: "https://github.com/GeekingwithMauri/NotificationsEngine",
    from: "0.1.0"
  ),
]
```

## Example of usage

```swift
// Keep a reference within the AppDelegate
lazy var remoteNotificationEngine: NotificationsEngineCenter = {
    return NotificationsEngineCenter(application: UIApplication.shared)
}()

// A recommended place to put it is on the application(_:didFinishLaunchingWithOptions:)` due to some vendor's inner workings (such as Firebase init swizzling)
func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    ...
    // This is done before any logging occurs. 
    remoteNotificationEngine.initialSetupShouldItBeNeeded()
    return true
}

// Use AppDelegate hook to register the device
func application(_ application: UIApplication,
                 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    remoteNotificationEngine.register(deviceToken: deviceToken)
}

func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
  // Investigate if something went wrong during push notification registration
}
```

Whenever a new notification arrives, they user could interact or not with it. In case they do, the app is brought from the background into the foreground in the OS. We must wait until the app is in an active state to operate. The sceneDidBecomeActive(_ scene: UIScene)` delegate from the _SceneDelegate_ is the ideal place to do so.

```swift
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
...
  // Reference to instance created in the AppDelegate
  private let remoteNotificationEngine = (UIApplication.shared.delegate as? AppDelegate)?.remoteNotificationEngine
  // Notification center from which we'll listen whether there's a user interaction queued
  private let notificationCenter: NotificationCenter = .default

  func scene(_ scene: UIScene,
             willConnectTo session: UISceneSession,
             options connectionOptions: UIScene.ConnectionOptions) {
    ...
    notificationCenter.addObserver(self,
                                   selector: #selector(processNotification),
                                   name: NotificationsEngineCenter.notificationReminder,
                                   object: nil)
  }

  // If the user opened the app from a notification, it's queued waiting to be executed.
  func sceneDidBecomeActive(_ scene: UIScene) {
    remoteNotificationEngine?.executeQueuedActionShouldItExist()
  }
  
  // Register method to interact with received notification from queued action
  func processNotification() {
    // Do whatever we need with the action received.
  }
}
```



## Current limitations
- For the time being, this only supports Firebase. 
- `GoogleService-Info` must be included in the main project
- Unit tests missing
