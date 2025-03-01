/* Copyright Airship and Contributors */

import Foundation

#if canImport(UIKit)
public import UIKit
#endif

#if canImport(AirshipCore)
import AirshipCore
#endif

/// Protocol to be implemented by push notification clients. All methods are optional.
@objc
public protocol UAPushNotificationDelegate: Sendable {
    /// Called when a notification is received in the foreground.
    ///
    /// - Parameters:
    ///   - userInfo: The notification info
    ///   - completionHandler: the completion handler to execute when notification processing is complete.
    @objc
    func receivedForegroundNotification(
        _ userInfo: [AnyHashable: Any],
        completionHandler: @escaping () -> Void
    )

#if !os(watchOS)
    /// Called when a notification is received in the background.
    ///
    /// - Parameters:
    ///   - userInfo: The notification info
    ///   - completionHandler: the completion handler to execute when notification processing is complete.
    @objc
    func receivedBackgroundNotification(
        _ userInfo: [AnyHashable: Any],
        completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    )
#else
    /// Called when a notification is received in the background.
    ///
    /// - Parameters:
    ///   - userInfo: The notification info
    ///   - completionHandler: the completion handler to execute when notification processing is complete.
    @objc
    func receivedBackgroundNotification(
        _ userInfo: [AnyHashable: Any],
        completionHandler: @escaping (WKBackgroundFetchResult) -> Void
    )
#endif

#if !os(tvOS)
    /// Called when a notification is received in the background or foreground and results in a user interaction.
    /// User interactions can include launching the application from the push, or using an interactive control on the notification interface
    /// such as a button or text field.
    ///
    /// - Parameters:
    ///   - notificationResponse: UNNotificationResponse object representing the user's response
    /// to the notification and the associated notification contents.
    ///
    ///   - completionHandler: the completion handler to execute when processing the user's response has completed.
    @objc
    func receivedNotificationResponse(
        _ notificationResponse: UNNotificationResponse,
        completionHandler: @escaping () -> Void
    )
#endif


    /// Called when a notification has arrived in the foreground and is available for display.
    ///
    /// - Parameters:
    ///   - options: The notification presentation options.
    ///   - notification: The notification.
    ///   - completionHandler: The completion handler.
    @objc(extendPresentationOptions:notification:completionHandler:)
    func extendPresentationOptions(
        _ options: UNNotificationPresentationOptions,
        notification: UNNotification,
        completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    )
}

@MainActor
final class UAPushNotificationDelegateWrapper: NSObject, PushNotificationDelegate {

    weak var forwardDelegate: (any UAPushNotificationDelegate)?

    init(_ forwardDelegate: any UAPushNotificationDelegate) {
        self.forwardDelegate = forwardDelegate
    }

    func receivedForegroundNotification(_ userInfo: [AnyHashable : Any]) async {
        await withCheckedContinuation { [forwardDelegate] continuation in
            forwardDelegate?.receivedForegroundNotification(userInfo) {
                continuation.resume()
            }
        }
    }

#if !os(watchOS)
    func receivedBackgroundNotification(_ userInfo: [AnyHashable : Any]) async -> UIBackgroundFetchResult {
        await withCheckedContinuation { [forwardDelegate] continuation in
            forwardDelegate?.receivedBackgroundNotification(userInfo) { result in
                continuation.resume(returning: result)
            }
        }
    }
#else
    func receivedBackgroundNotification(_ userInfo: [AnyHashable : Any]) async -> WKBackgroundFetchResult {
        await withCheckedContinuation { [forwardDelegate] continuation in
            forwardDelegate?.receivedBackgroundNotification(userInfo) { result in
                continuation.resume(returning: result)
            }
        }
    }
#endif

#if !os(tvOS)
    func receivedNotificationResponse(_ notificationResponse: UNNotificationResponse) async {
        await withCheckedContinuation { [forwardDelegate] continuation in
            forwardDelegate?.receivedNotificationResponse(notificationResponse) {
                continuation.resume()
            }
        }
    }
#endif

    func extendPresentationOptions(_ options: UNNotificationPresentationOptions, notification: UNNotification) async -> UNNotificationPresentationOptions {
        await withCheckedContinuation { [forwardDelegate] continuation in
            forwardDelegate?.extendPresentationOptions(options, notification: notification) { result in
                continuation.resume(returning: result)
            }
        }
    }

    @MainActor
    public func receivedForegroundNotification(
        _ userInfo: [AnyHashable: Any],
        completionHandler: @escaping () -> Void
    ) {
        guard let forwardDelegate  else {
            completionHandler()
            return
        }

        forwardDelegate.receivedForegroundNotification(userInfo, completionHandler: completionHandler)
    }
    
    #if !os(watchOS)
    @MainActor
    public func receivedBackgroundNotification(
       _ userInfo: [AnyHashable: Any],
       completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        guard let forwardDelegate  else {
            completionHandler(.noData)
            return
        }

        forwardDelegate.receivedBackgroundNotification(userInfo, completionHandler: completionHandler)
    }
    
    #else
    
    public func receivedBackgroundNotification(
        _ userInfo: [AnyHashable: Any],
        completionHandler: @escaping (WKBackgroundFetchResult) -> Void
    ) {
        guard let forwardDelegate  else {
            completionHandler(.noData)
            return
        }

        forwardDelegate.receivedBackgroundNotification(userInfo, completionHandler: completionHandler)
    }
    
    #endif
    #if !os(tvOS)
    @MainActor
    public func receivedNotificationResponse(
       _ notificationResponse: UNNotificationResponse,
       completionHandler: @escaping () -> Void
    ) {
        guard let forwardDelegate  else {
            completionHandler()
            return
        }
        forwardDelegate.receivedNotificationResponse(notificationResponse, completionHandler: completionHandler)
    }
    
    #endif
    @MainActor
    public func extendPresentationOptions(
        _ options: UNNotificationPresentationOptions,
        notification: UNNotification,
        completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        guard let forwardDelegate  else {
            completionHandler(options)
            return
        }

        forwardDelegate.extendPresentationOptions(options, notification: notification, completionHandler: completionHandler)
    }
}
