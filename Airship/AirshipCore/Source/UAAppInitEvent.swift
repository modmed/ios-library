/* Copyright Airship and Contributors */

/**
 * @note For Interrnal use only :nodoc:
 */
@objc
public class UAAppInitEvent : NSObject, UAEvent {

    @objc
    public var analyticsSupplier: () -> AnalyticsProtocol? = {
        return UAirship.analytics()
    }

    @objc
    public var priority: UAEventPriority {
        get {
            return .normal
        }
    }

    
    @objc
    public var eventType : String {
        get {
            return "app_init"
        }
    }

    @objc
    public var data: [AnyHashable : Any] {
        get {
            return self.gatherData()
        }
    }

    open func gatherData() -> [AnyHashable : Any] {
        var data: [AnyHashable : Any] = [:]

        data["push_id"] = self.analyticsSupplier()?.conversionSendID
        data["metadata"] = self.analyticsSupplier()?.conversionPushMetadata
        data["carrier"] = UAUtils.carrierName()
        data["connection_type"] = UAUtils.connectionType()

        data["notification_types"] = UAEventUtils.notificationTypes()
        data["notification_authorization"] = UAEventUtils.notificationAuthorization()

        let localtz = NSTimeZone.default as NSTimeZone
        data["time_zone"] = NSNumber(value: Double(localtz.secondsFromGMT))
        data["daylight_savings"] = localtz.isDaylightSavingTime ? "true" : "false"

        // Component Versions
        data["os_version"] = UIDevice.current.systemVersion
        data["lib_version"] = UAirshipVersion.get()

        let packageVersion = UAUtils.bundleShortVersionString() ?? ""
        data["package_version"] = packageVersion

        // Foreground
        let isInForeground = UAAppStateTracker.shared.state != .background
        data["foreground"] = isInForeground ? "true" : "false"

        return data
    }
}