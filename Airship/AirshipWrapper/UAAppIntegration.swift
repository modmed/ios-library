/* Copyright Airship and Contributors */

import Foundation
import AirshipCore

@preconcurrency import UserNotifications

/// Application hooks required by Airship. If `automaticSetupEnabled` is enabled
/// (enabled by default), Airship will automatically integrate these calls into
/// the application by swizzling methods. If `automaticSetupEnabled` is disabled,
/// the application must call through to every method provided by this class.
@objc
public class UAAppIntegration: NSObject {
    
#if !os(watchOS)
    
    /**
     * Must be called by the UIApplicationDelegate's
     * application:performFetchWithCompletionHandler:.
     *
     * - Parameters:
     *   - application: The application
     *   - completionHandler: The completion handler.
     */
    @objc(application:performFetchWithCompletionHandler:)
    public class func application(
        _ application: UIApplication,
        performFetchWithCompletionHandler completionHandler: @Sendable @escaping (
            UIBackgroundFetchResult
        ) -> Void
    ) {
        Task { @MainActor in
            AppIntegration.application(application, performFetchWithCompletionHandler: completionHandler)
        }
    }
    
    /**
     * Must be called by the UIApplicationDelegate's
     * application:didRegisterForRemoteNotificationsWithDeviceToken:.
     *
     * - Parameters:
     *   - application: The application
     *   - deviceToken: The device token.
     */
    @objc(application:didRegisterForRemoteNotificationsWithDeviceToken:)
    public class func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            AppIntegration.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        }
    }
    
    /**
     * Must be called by the UIApplicationDelegate's
     * application:didFailToRegisterForRemoteNotificationsWithError:.
     *
     * - Parameters:
     *   - application: The application
     *   - error: The error.
     */
    @objc
    public class func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: any Error
    ) {
        Task { @MainActor in
            AppIntegration.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
        }
    }
    
    /**
     * Must be called by the UIApplicationDelegate's
     * application:didReceiveRemoteNotification:fetchCompletionHandler:.
     *
     * - Parameters:
     *   - application: The application
     *   - userInfo: The remote notification.
     *   - completionHandler: The completion handler.
     */
    @objc
    @MainActor
    public class func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @Sendable @escaping (
            UIBackgroundFetchResult
        ) -> Void
    ) {
        Task { @MainActor in
            AppIntegration.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
        }
    }
#else
    /**
     * Must be called by the WKExtensionDelegate's
     * didRegisterForRemoteNotificationsWithDeviceToken:.
     *
     * - Parameters:
     *   - deviceToken: The device token.
     */
    @objc(didRegisterForRemoteNotificationsWithDeviceToken:)
    public class func didRegisterForRemoteNotificationsWithDeviceToken(
        deviceToken: Data
    ) {
        AppIntegration.didRegisterForRemoteNotificationsWithDeviceToken(deviceToken)
    }
    
    /**
     * Must be called by the WKExtensionDelegate's
     * didFailToRegisterForRemoteNotificationsWithError:.
     *
     * - Parameters:
     *   - error: The error.
     */
    @objc
    public class func didFailToRegisterForRemoteNotificationsWithError(
        error: Error
    ) {
        AppIntegration.didFailToRegisterForRemoteNotificationsWithError(error)
    }
    /**
     * Must be called by the WKExtensionDelegate's
     * didReceiveRemoteNotification:fetchCompletionHandler:.
     *
     * - Parameters:
     *   - userInfo: The remote notification.
     *   - completionHandler: The completion handler.
     */
    @objc
    public class func didReceiveRemoteNotification(
        userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (
            WKBackgroundFetchResult
        ) -> Void
    ) {
        AppIntegration.didReceiveRemoteNotification(userInfo: userInfo, fetchCompletionHandler:completionHandler)
    }
#endif
    
    /**
     * Must be called by the UNUserNotificationDelegate's
     * userNotificationCenter:willPresentNotification:withCompletionHandler.
     *
     * - Parameters:
     *   - center: The notification center.
     *   - notification: The notification.
     *   - completionHandler: The completion handler.
     */
    @objc(userNotificationCenter:willPresentNotification:withCompletionHandler:)
    public class func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @Sendable @escaping (
            _ options: UNNotificationPresentationOptions
        ) -> Void
    ) {
        Task { @MainActor in
            AppIntegration.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
        }
    }
    
#if !os(tvOS)
    /**
     * Must be called by the UNUserNotificationDelegate's
     * userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler.
     *
     * - Parameters:
     *   - center: The notification center.
     *   - response: The notification response.
     *   - completionHandler: The completion handler.
     */
    @objc(
        userNotificationCenter:
            didReceiveNotificationResponse:
            withCompletionHandler:
    )
    public class func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @Sendable @escaping () -> Void
    ) {
        Task { @MainActor in
            AppIntegration.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
        }
    }
#endif
}
