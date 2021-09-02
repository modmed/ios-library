/* Copyright Airship and Contributors */

import XCTest

@testable
import AirshipCore

class DefaultAppIntegrationdelegateTest: XCTestCase {

    private var delegate: DefaultAppIntegrationDelegate!
    private let push = TestPush()
    private let analytics = TestAnalytics()
    private let pushableComponent = TestPushableComponent()
    
    override func setUpWithError() throws {
        self.delegate = DefaultAppIntegrationDelegate(push: self.push,
                                                      analytics: self.analytics,
                                                      pushableComponents: [pushableComponent])
    }
    
    func testOnBackgroundAppRefresh() throws {
        delegate.onBackgroundAppRefresh()
        XCTAssertTrue(push.updateAuthorizedNotificationTypesCalled)
    }
    
    func testDidRegisterForRemoteNotifications() throws {
        let data = Data()
        delegate.didRegisterForRemoteNotifications(deviceToken: data)
        XCTAssertEqual(data, push.deviceToken)
        XCTAssertTrue(self.analytics.onDeviceRegistrationCalled)
    }
    
    func testDidFailToRegisterForRemoteNotifications() throws {
        let error = AirshipErrors.error("some error")
        delegate.didFailToRegisterForRemoteNotifications(error: error)
        XCTAssertEqual("some error", error.localizedDescription)
    }
    
    func testDidReceiveRemoteNotification() throws {
        let expectedUserInfo = ["neat": "story"]

        self.push.didReceiveRemoteNotificationCallback = { userInfo, isForeground, completionHandler in
            XCTAssertEqual(expectedUserInfo as NSDictionary, userInfo as NSDictionary)
            XCTAssertTrue(isForeground)
            completionHandler(.noData)
        }
        
        self.pushableComponent.didReceiveRemoteNotificationCallback = { userInfo, completionHandler in
            XCTAssertEqual(expectedUserInfo as NSDictionary, userInfo as NSDictionary)
            completionHandler(.newData)
        }

        let delegateCalled = expectation(description: "callback called")
        delegate.didReceiveRemoteNotification(userInfo: expectedUserInfo, isForeground: true) { result in
            XCTAssertEqual(result, .newData)
            delegateCalled.fulfill()
        }
        
        self.wait(for: [delegateCalled], timeout: 10)
    }
}


class TestPush : InternalPushProtocol {
    var updateAuthorizedNotificationTypesCalled = false
    var deviceToken: Data?
    var registrationError: Error?
    var didReceiveRemoteNotificationCallback: (([AnyHashable : Any], Bool, @escaping (UIBackgroundFetchResult) -> Void) -> Void)?
    var combinedCategories: Set<UNNotificationCategory> = Set()
    
    func updateAuthorizedNotificationTypes() {
        self.updateAuthorizedNotificationTypesCalled = true
    }
    
    func didRegisterForRemoteNotifications(_ deviceToken: Data) {
        self.deviceToken = deviceToken
    }
    
    func didFailToRegisterForRemoteNotifications(_ error: Error) {
        self.registrationError = error
    }
    
    func didReceiveRemoteNotification(_ userInfo: [AnyHashable : Any],
                                      isForeground: Bool,
                                      completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        self.didReceiveRemoteNotificationCallback!(userInfo, isForeground, completionHandler)
    }
    
    func presentationOptionsForNotification(_ notification: UNNotification) -> UNNotificationPresentationOptions {
        assertionFailure("Unable to create UNNotification in tests.")
        return []
    }
    
    func didReceiveNotificationResponse(_ response: UNNotificationResponse, completionHandler: @escaping () -> Void) {
        assertionFailure("Unable to create UNNotificationResponse in tests.")
    }
}

class TestPushableComponent : UAPushableComponent {
    var didReceiveRemoteNotificationCallback: (([AnyHashable : Any], @escaping (UIBackgroundFetchResult) -> Void) -> Void)?

    public func receivedRemoteNotification(_ notification: [AnyHashable: Any], completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        self.didReceiveRemoteNotificationCallback!(notification, completionHandler)
    }

    public func receivedNotificationResponse(_ response: UNNotificationResponse, completionHandler: @escaping () -> Void) {
        assertionFailure("Unable to create UNNotificationResponse in tests.")
    }
}

class TestAnalytics : InternalAnalyticsProtocol {
    
    var onDeviceRegistrationCalled = false

    func onDeviceRegistration() {
        onDeviceRegistrationCalled = true
    }
    
    func onNotificationResponse(response: UNNotificationResponse, action: UNNotificationAction?) {
        assertionFailure("Unable to create UNNotificationResponse in tests.")
    }
    
}