/* Copyright Airship and Contributors */

import Foundation
public import AirshipCore

@objc
public protocol UANativeBridgeDelegate {
    /// Called when `UAirship.close()` is triggered from the JavaScript environment.
    func close()
}

public class UANativeBridgeDelegateWrapper: NSObject, NativeBridgeDelegate {
    private let delegate: UANativeBridgeDelegate
    
    init(delegate: UANativeBridgeDelegate) {
        self.delegate = delegate
    }
    
    public func close() {
        self.delegate.close()
    }
    
}
