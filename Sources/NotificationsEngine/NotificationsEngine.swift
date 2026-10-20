import UIKit
import Firebase
import FirebaseMessaging

/// Possible notification errors with user interaction
public enum NotificationError: Error {
    case userDeclined
}

/// NotificationEngine center of control
public final class NotificationsEngineCenter: NSObject {
    private let remoteNotificationCenter: UNUserNotificationCenter
    private let notificationCenter: NotificationCenter
    private var userDidInteractWithReminder: Bool
    private var tappedNotificationUserInfo: [AnyHashable: Any]?
    private unowned var application: UIApplication

    /// Notification's name to be hooked in. This will be triggered once the app is in an active state in the foreground.
    ///
    /// The posted `Notification.userInfo` is the tapped notification's payload.
    public static let notificationReminder: NSNotification.Name = NSNotification.Name("notificationReminder")

    /// Called with the latest FCM registration token — on first registration and on every refresh. `nil` means the token was invalidated.
    ///
    /// Set it before `initialSetupShouldItBeNeeded()` / `requestUserPermission(completionHandler:)` so the initial token isn't missed.
    public var onRegistrationToken: ((String?) -> Void)?

    /// Called for a notification that arrives while the app is in the foreground. Returns how to present it.
    /// nil (the default) presents nothing — today's behaviour.
    public var onForegroundNotification: (([AnyHashable: Any]) -> UNNotificationPresentationOptions)?

    /// Default init
    /// - Parameters:
    ///   - remoteNotificationCenter: app's remote notification center. Defaults to the `.current()`
    ///   - notificationCenter: vanilla notification center instance to be injected. Defaults to the `.current`
    ///   - userDidInteractWithGameReminder: flag that sets whether the user interacted or not with a notification received. Defaults to the `false`
    ///   - application: app's `UIApplication` instance reference. This is usually accessed in the AppDelegate as `UIApplication.shared`
    public init(
        remoteNotificationCenter: UNUserNotificationCenter = .current(),
        notificationCenter: NotificationCenter = .default,
        userDidInteractReminder: Bool = false,
        application: UIApplication
    ) {
        self.remoteNotificationCenter = remoteNotificationCenter
        self.notificationCenter = notificationCenter
        self.userDidInteractWithReminder = userDidInteractReminder
        self.application = application
    }

    /// Initializes the SDK in case it hasn't to previously
    public func initialSetupShouldItBeNeeded() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        setupNotifications()
    }

    /// Requests user permission to receive notifications.
    ///
    /// `alert`, `.badge`, and `.sound` alert's type are requested
    public func requestUserPermission(completionHandler: @escaping (Result<Void, Error>) -> Void) {
        remoteNotificationCenter.requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { [weak self] wasPermissionGranted, error in

            guaranteeMainThread {
                if wasPermissionGranted {
                    self?.setupNotifications()

                    completionHandler(.success(()))
                } else if !wasPermissionGranted {
                    completionHandler(.failure(NotificationError.userDeclined))
                } else if let foundError = error {
                    completionHandler(.failure(foundError))
                }
            }
        }
    }

    /// Register device fingerprint
    /// - Parameter deviceToken: token data to be register for SDK vendor
    public func register(deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    /// Posts a notification via `NotificationCenter` in case the user opened the app via a remote notification.
    /// Its `userInfo` is the tapped notification's payload.
    ///
    /// Regardless of the case, it **always** resets the app's badge count to `0`.
    public func executeQueuedActionShouldItExist() {
        remoteNotificationCenter.setBadgeCount(0)

        guard userDidInteractWithReminder else {
            return
        }

        notificationCenter.post(
            Notification(
                name: Self.notificationReminder,
                object: nil,
                userInfo: tappedNotificationUserInfo
            )
        )
        userDidInteractWithReminder = false
        tappedNotificationUserInfo = nil
    }
}

private extension NotificationsEngineCenter {
    func setupNotifications() {
        remoteNotificationCenter.delegate = self
        Messaging.messaging().delegate = self

        application.registerForRemoteNotifications()
    }

    func logRemoteInfo(basedOn notification: UNNotification) {
        let userInfo = notification.request.content.userInfo

        Messaging.messaging().appDidReceiveMessage(userInfo)
    }
}

extension NotificationsEngineCenter: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        logRemoteInfo(basedOn: response.notification)

        userDidInteractWithReminder = true
        tappedNotificationUserInfo = response.notification.request.content.userInfo
        completionHandler()
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        logRemoteInfo(basedOn: notification)

        completionHandler(onForegroundNotification?(notification.request.content.userInfo) ?? [])
    }
}

extension NotificationsEngineCenter: MessagingDelegate {
    public func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        onRegistrationToken?(fcmToken)
    }
}
