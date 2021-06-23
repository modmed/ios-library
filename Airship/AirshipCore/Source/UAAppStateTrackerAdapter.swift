/* Copyright Airship and Contributors */

import Foundation
import UIKit

/// Delegate protocol for app state tracker callbacks.

@objc
public protocol UAAppStateTrackerDelegate {
    /// The application became active.
    func applicationDidBecomeActive()
    /// The application is about to become active.
    func applicationWillEnterForeground()
    /// The application entered the background.
    func applicationDidEnterBackground()
    /// The application is about to leave the active state.
    func applicationWillResignActive()
    /// The application is about to terminate.
    func applicationWillTerminate()
}

/// Protocol for tracking application state. Classes implementing this protocol should be able to report
/// current application state, and send callbacks to an optional delegate object implementing the UAAppStateTrackerDelegate protocol.
@objc
public protocol UAAppStateTrackerAdapter {

    /// The current application state.
    var state: UAApplicationState { get }

    /// The state tracker delegate.
    var stateTrackerDelegate: UAAppStateTrackerDelegate? { get set }
}
