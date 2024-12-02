/* Copyright Airship and Contributors */

import Foundation
import AirshipCore

/**
 * Airship manages the shared state for all Airship services. Airship.takeOff should be
 * called from within your application delegate's `application:didFinishLaunchingWithOptions:` method
 * to initialize the shared instance.
 */

/// Main entry point for Airship. The application must call `takeOff` during `application:didFinishLaunchingWithOptions:`
/// before accessing any instances on Airship or Airship modules.
@objc
public class UAAirship: NSObject {
    
    private static let _holder = Holder()
    
    /// A user configurable deep link delegate.
    private static var _deepLinkDelegate: (any DeepLinkDelegate)? {
        get { return _holder.deeplinkDelegate.value }
        set { _holder.deeplinkDelegate.value = newValue }
    }
    
    @objc
    public static var deepLinkDelegate: (any UADeepLinkDelegate)? {
        get { return _holder.uaDeepLinkDelegate.value }
        set {
            _holder.uaDeepLinkDelegate.value = newValue
            if let newValue {
                let wrapper = UADeepLinkDelegateWrapper(delegate: newValue)
                self._deepLinkDelegate = wrapper
                Airship.deepLinkDelegate = wrapper
            } else {
                self._deepLinkDelegate = nil
                Airship.deepLinkDelegate = nil
            }
        }
    }
    
#if !os(watchOS)
    
    /// Initializes Airship. Config will be read from `AirshipConfig.plist`.
    /// - Parameters:
    ///     - launchOptions: The launch options passed into `application:didFinishLaunchingWithOptions:`.
    @objc
    @MainActor
    public class func takeOff(
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) {
        Airship.takeOff(launchOptions: launchOptions)
    }

    /// Initializes Airship.
    /// - Parameters:
    ///     - config: The Airship config.
    ///     - launchOptions: The launch options passed into `application:didFinishLaunchingWithOptions:`.
    @objc
    @MainActor
    public class func takeOff(
        _ config: UAAirshipConfig?,
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) {
        Airship.takeOff(config?.config, launchOptions: launchOptions)
    }

#else

    /// Initializes Airship. Config will be read from `AirshipConfig.plist`.
    @objc
    @MainActor
    public class func takeOff() {
        Airship.takeOff(nil)
    }

    /// Initializes Airship.
    /// - Parameters:
    ///     - config: The Airship config.
    @objc
    @MainActor
    public class func takeOff(_ config: AirshipConfig?) {
        Airship.takeOff(config)
    }
    
#endif
    
    private final class Holder: Sendable {
        let deeplinkDelegate = AirshipAtomicValue<(any DeepLinkDelegate)?>(nil)
        let uaDeepLinkDelegate = AirshipAtomicValue<(any UADeepLinkDelegate)?>(nil)
    }
    
}

/// NSNotificationCenter keys event names
@objc(UAAirshipNotifications)
public final class UAAirshipNotifications: NSObject {

    /// Notification when Airship is ready.
    @objc(UAAirshipNotificationsAirshipReady)
    public final class UAAirshipReady: NSObject {
        /// Notification name
        @objc
        public static let name = NSNotification.Name(
            "com.urbanairship.airship_ready"
        )

        /// Airship ready channel ID key. Only available if `extendedBroadcastEnabled` is true in config.
        @objc
        public static let channelIDKey = "channel_id"

        /// Airship ready app key. Only available if `extendedBroadcastEnabled` is true in config.
        @objc
        public static let appKey = "app_key"

        /// Airship ready payload version. Only available if `extendedBroadcastEnabled` is true in config.
        @objc
        public static let payloadVersionKey = "payload_version"
    }
}
