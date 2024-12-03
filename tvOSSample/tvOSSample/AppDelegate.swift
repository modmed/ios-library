/* Copyright Urban Airship and Contributors */

import AirshipCore
import AirshipPreferenceCenter
import UIKit


class AppDelegate: UIResponder, UIApplicationDelegate, DeepLinkDelegate, PreferenceCenterOpenDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        var config = AirshipConfig.default()
        config.productionLogLevel = .verbose
        config.developmentLogLevel = .verbose

        Airship.takeOff(config, launchOptions: launchOptions)

        Airship.channel.editTags { $0.add(["tvos"]) }
        Airship.deepLinkDelegate = self
//        MessageCenter.shared.displayDelegate = self
        PreferenceCenter.shared.openDelegate = self

        NotificationCenter.default.addObserver(
            forName: AppStateTracker.didBecomeActiveNotification,
            object: nil,
            queue: nil
        ) { _ in
            Task {
                // Set the icon badge to zero
                do {
                    try await Airship.push.resetBadge()
                } catch {
                    AirshipLogger.error("failed to reset badge")
                }
            }
        }

        return true
    }

    func showInvalidDeepLinkAlert(_ url: URL) {
        AppState.shared.toastMessage = Toast.Message(
            text: "App does not know how to handle deepLink \(url)",
            duration: 2.0
        )
    }

    @MainActor
    func receivedDeepLink(_ deepLink: URL) async  {
        guard deepLink.host?.lowercased() == "deeplink" else {
            self.showInvalidDeepLinkAlert(deepLink)
            return
        }

        let components = deepLink.path.lowercased().split(separator: "/")
        switch components.first {
        case "home":
            AppState.shared.homeDestination = nil
            AppState.shared.selectedTab = .home
        case "preferences":
            AppState.shared.selectedTab = .preferenceCenter
        case "message_center":
            AppState.shared.selectedTab = .messageCenter
        default:
            self.showInvalidDeepLinkAlert(deepLink)
        }
    }
//
//    func displayMessageCenter(messageID: String) {
//        AppState.shared.selectedTab = .messageCenter
//        AppState.shared.messageCenterController.navigate(messageID: messageID)
//    }
//
//    func displayMessageCenter() {
//        AppState.shared.selectedTab = .messageCenter
//    }
//
//    func dismissMessageCenter() {
//    }

    @MainActor
    func openPreferenceCenter(_ preferenceCenterID: String) -> Bool {
        guard preferenceCenterID == MainApp.preferenceCenterID else {
            return false
        }

        AppState.shared.selectedTab = .preferenceCenter
        return true
    }
}
