#if canImport(AirshipCore)
import AirshipCore
#endif

import Foundation

/// Action runner for in-app experiences. Must be used in order to properly attribute custom events to the message.
public protocol InAppActionRunner: Sendable {
    // Runs an action.
    /// - Parameters:
    ///     - actionName: The action name.
    ///     - arguments: The action arguments.
    /// - Returns: Action result.
    @MainActor
    func run(actionName: String, arguments: ActionArguments) async -> ActionResult

    /// Runs actions asynchronously.
    /// - Parameters:
    ///     - actions: The actions payload
    @MainActor
    func runAsync(actions: AirshipJSON)

    // Runs actions.
    /// - Parameters:
    ///     - actions: The actions payload
    @MainActor
    func run(actions: AirshipJSON) async
}

protocol InternalInAppActionRunner: InAppActionRunner, ThomasActionRunner {

}

final class DefaultInAppActionRunner: InternalInAppActionRunner {
    private let analytics: InAppMessageAnalyticsProtocol
    private let trackPermissionResults: Bool

    init(analytics: InAppMessageAnalyticsProtocol, trackPermissionResults: Bool) {
        self.analytics = analytics
        self.trackPermissionResults = trackPermissionResults
    }

    @MainActor
    func extendMetadata(
        _ metadata: inout [String: Sendable],
        layoutContext: ThomasLayoutContext? = nil
    ) {
        if trackPermissionResults {
            let permissionReceiver: @Sendable (
                AirshipPermission,
                AirshipPermissionStatus,
                AirshipPermissionStatus
            ) async -> Void = { [analytics] permission, start, end in
                await analytics.recordEvent(
                    InAppPermissionResultEvent(
                        permission: permission,
                        startingStatus: start,
                        endingStatus: end
                    ),
                    layoutContext: layoutContext
                )
            }

            metadata[PromptPermissionAction.resultReceiverMetadataKey] = permissionReceiver
        }


        metadata[AddCustomEventAction._inAppMetadata] = analytics.makeCustomEventContext(
            layoutContext: layoutContext
        )
    }

    @MainActor
    public func run(actionName: String, arguments: ActionArguments) async -> ActionResult {
        var mutated = arguments
        self.extendMetadata(&mutated.metadata)
        return await ActionRunner.run(actionName: actionName, arguments: mutated)
    }

    @MainActor
    public func runAsync(actions: AirshipJSON) {
        var metadata: [String: Sendable] = [:]
        self.extendMetadata(&metadata)

        Task {
            await self.run(actions: actions)
        }
    }

    @MainActor
    public func run(actions: AirshipJSON) async {
        var metadata: [String: Sendable] = [:]
        self.extendMetadata(&metadata)

        await ActionRunner.run(
            actionsPayload: actions,
            situation: .automation,
            metadata: metadata
        )
    }

    @MainActor
    public func runAsync(actions: AirshipJSON, layoutContext: ThomasLayoutContext?) {
        var metadata: [String: Sendable] = [:]
        self.extendMetadata(&metadata, layoutContext: layoutContext)

        Task {
            await ActionRunner.run(
                actionsPayload: actions,
                situation: .automation,
                metadata: metadata
            )
        }
    }

    @MainActor
    public func run(actionName: String, arguments: ActionArguments, layoutContext: ThomasLayoutContext?) async -> ActionResult {
        var args = arguments
        self.extendMetadata(&args.metadata, layoutContext: layoutContext)
        return await ActionRunner.run(actionName: actionName, arguments: arguments)
    }
}

protocol InAppActionRunnerFactoryProtocol: Sendable {
    func makeRunner(message: InAppMessage, analytics: InAppMessageAnalyticsProtocol) -> InternalInAppActionRunner
}


final class InAppActionRunnerFactory: InAppActionRunnerFactoryProtocol {
    func makeRunner(message: InAppMessage, analytics: InAppMessageAnalyticsProtocol) -> InternalInAppActionRunner {
        return DefaultInAppActionRunner(
            analytics: analytics,
            trackPermissionResults: message.isAirshipLayout
        )
    }
}
