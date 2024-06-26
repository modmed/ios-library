/* Copyright Airship and Contributors */

import Foundation

#if canImport(AirshipCore)
import AirshipCore
#endif


/**
 * Provides a control interface for creating, canceling and executing in-app automations.
 */
public final class InAppAutomation: Sendable {

    private let engine: AutomationEngineProtocol
    private let remoteDataSubscriber: AutomationRemoteDataSubscriberProtocol
    private let dataStore: PreferenceDataStore
    private let privacyManager: AirshipPrivacyManager
    private let notificationCenter: AirshipNotificationCenter
    private static let pausedStoreKey: String = "UAInAppMessageManagerPaused"
    private let _legacyInAppMessaging: InternalLegacyInAppMessagingProtocol

    /// In-App Messaging
    public let inAppMessaging: InAppMessagingProtocol

    /// Legacy In-App Messaging
    public var legacyInAppMessaging: LegacyInAppMessagingProtocol {
        return _legacyInAppMessaging
    }

    /// The shared InAppAutomation instance. `Airship.takeOff` must be called before accessing this instance.
    public static var shared: InAppAutomation {
        return Airship.requireComponent(ofType: InAppAutomationComponent.self).inAppAutomation
    }

    @MainActor
    init(
        engine: AutomationEngineProtocol,
        inAppMessaging: InAppMessagingProtocol,
        legacyInAppMessaging: InternalLegacyInAppMessagingProtocol,
        remoteDataSubscriber: AutomationRemoteDataSubscriberProtocol,
        dataStore: PreferenceDataStore,
        privacyManager: AirshipPrivacyManager,
        config: RuntimeConfig,
        notificationCenter: AirshipNotificationCenter = .shared
    ) {
        self.engine = engine
        self.inAppMessaging = inAppMessaging
        self._legacyInAppMessaging = legacyInAppMessaging
        self.remoteDataSubscriber = remoteDataSubscriber
        self.dataStore = dataStore
        self.privacyManager = privacyManager
        self.notificationCenter = notificationCenter

        if (config.autoPauseInAppAutomationOnLaunch) {
            self.isPaused = true
        }
    }

    /// Paused state of in-app automation.
    @MainActor
    public var isPaused: Bool {
        get {
            return self.dataStore.bool(forKey: Self.pausedStoreKey)
        }
        set {
            self.dataStore.setBool(newValue, forKey: Self.pausedStoreKey)
            self.engine.setExecutionPaused(newValue)
        }
    }

    /// Creates the provided schedules or updates them if they already exist.
    /// - Parameter schedules: The schedules to create or update.
    public func upsertSchedules(_ schedules: [AutomationSchedule]) async throws {
        try await self.engine.upsertSchedules(schedules)
    }

    /// Cancels an in-app automation via its schedule identifier.
    /// - Parameter identifier: The schedule identifier to cancel.
    public func cancelSchedule(identifier: String) async throws {
        try await self.engine.cancelSchedules(identifiers: [identifier])
    }

    /// Cancels multiple in-app automations via their schedule identifiers.
    /// - Parameter identifiers: The schedule identifiers to cancel.
    public func cancelSchedule(identifiers: [String]) async throws {
        try await self.engine.cancelSchedules(identifiers: identifiers)
    }

    /// Cancels multiple in-app automations via their group.
    /// - Parameter group: The group to cancel.
    public func cancelSchedules(group: String) async throws {
        try await self.engine.cancelSchedules(group: group)
    }
    
    func cancelSchedulesWith(type: AutomationSchedule.ScheduleType) async throws {
        try await self.engine.cancelSchedulesWith(type: type)
    }

    /// Gets the in-app automation with the provided schedule identifier.
    /// - Parameter identifier: The schedule identifier.
    /// - Returns: The in-app automation corresponding to the provided schedule identifier.
    public func getSchedule(identifier: String) async throws -> AutomationSchedule? {
        return try await self.engine.getSchedule(identifier: identifier)
    }

    /// Gets the in-app automation with the provided group.
    /// - Parameter identifier: The group to get.
    /// - Returns: The in-app automation corresponding to the provided group.
    public func getSchedules(group: String) async throws -> [AutomationSchedule] {
        return try await self.engine.getSchedules(group: group)
    }

    @MainActor
    private func privacyManagerUpdated() {
        if self.privacyManager.isEnabled(.inAppAutomation) {
            self.engine.setEnginePaused(false)
            self.remoteDataSubscriber.subscribe()
        } else {
            self.engine.setEnginePaused(true)
            self.remoteDataSubscriber.unsubscribe()
        }
    }
}

extension InAppAutomation {
    @MainActor
    func airshipReady() {
        self.engine.setExecutionPaused(self.isPaused)

        Task {
            await self.engine.start()
        }

        self.notificationCenter.addObserver(forName: AirshipNotifications.PrivacyManagerUpdated.name) { [weak self] _ in
            self?.privacyManagerUpdated()
        }
        self.privacyManagerUpdated()
    }

    func receivedRemoteNotification(
        _ notification: [AnyHashable: Any],
        completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        self._legacyInAppMessaging.receivedRemoteNotification(notification, completionHandler: completionHandler)
    }

    func receivedNotificationResponse(_ response: UNNotificationResponse, completionHandler: @escaping () -> Void) {
        self._legacyInAppMessaging.receivedNotificationResponse(response, completionHandler: completionHandler)
    }
}


