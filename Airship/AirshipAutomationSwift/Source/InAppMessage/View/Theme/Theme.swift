/* Copyright Airship and Contributors */

import Foundation
import SwiftUI

enum Theme {
    case banner(BannerTheme)
    case modal(ModalTheme)
    case fullScreen(FullScreenTheme)
    case html(HTMLTheme)

    var bannerTheme: BannerTheme {
        if case .banner(let theme) = self {
            return theme
        }
        return BannerTheme()
    }

    var modalTheme: ModalTheme {
        if case .modal(let theme) = self {
            return theme
        }
        return ModalTheme()
    }

    var fullScreenTheme: FullScreenTheme {
        if case .fullScreen(let theme) = self {
            return theme
        }
        return FullScreenTheme()
    }

    var htmlTheme: HTMLTheme {
        if case .html(let theme) = self {
            return theme
        }

        return HTMLTheme()
    }

    static let defaultButtonHeight: CGFloat = 33
    static let defaultFooterHeight: CGFloat = 33

    static let defaultStackedButtonSpacing: CGFloat = 24
    static let defaultSeparatedButtonSpacing: CGFloat = 16
}

extension BannerTheme: ThemeDefaultable {
    static let defaultPlistName: String = "UAInAppMessageBannerStyle.plist"

    static var defaultValues: BannerTheme {
        let defaultPadding = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        let defaultHeaderPadding = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        let defaultBodyPadding = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        let defaultMediaPadding = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        let defaultButtonPadding = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

        return BannerTheme(
            additionalPadding: defaultPadding,
            maxWidth: 0,
            headerTheme: TextTheme(letterSpacing: 0,
                                   lineSpacing: 0,
                                   additionalPadding: defaultHeaderPadding),
            bodyTheme: TextTheme(letterSpacing: 0,
                                 lineSpacing: 0,
                                 additionalPadding: defaultBodyPadding),
            mediaTheme: MediaTheme(additionalPadding: defaultMediaPadding),
            buttonTheme: ButtonTheme(buttonHeight: Theme.defaultButtonHeight,
                                     stackedButtonSpacing: Theme.defaultStackedButtonSpacing,
                                     separatedButtonSpacing: Theme.defaultSeparatedButtonSpacing,
                                     additionalPadding: defaultButtonPadding)
        )
    }
}

extension ModalTheme: ThemeDefaultable {
    static let defaultPlistName: String = "UAInAppMessageModalStyle.plist"

    static var defaultValues: ModalTheme {
        let defaultPadding = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        let defaultHeaderPadding = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        let defaultBodyPadding = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        let defaultMediaPadding = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        let defaultButtonPadding = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

        return ModalTheme(
            additionalPadding: defaultPadding,
            headerTheme: TextTheme(letterSpacing: 0,
                                   lineSpacing: 0,
                                   additionalPadding: defaultHeaderPadding),
            bodyTheme: TextTheme(letterSpacing: 0,
                                 lineSpacing: 0,
                                 additionalPadding: defaultBodyPadding),
            mediaTheme: MediaTheme(additionalPadding: defaultMediaPadding),
            buttonTheme: ButtonTheme(buttonHeight: Theme.defaultButtonHeight,
                                     stackedButtonSpacing: Theme.defaultStackedButtonSpacing,
                                     separatedButtonSpacing: Theme.defaultSeparatedButtonSpacing,
                                     additionalPadding: defaultButtonPadding),
            dismissIconResource: "xmark",
            maxWidth: 0,
            maxHeight: 0
        )
    }
}

extension FullScreenTheme: ThemeDefaultable {
    static let defaultPlistName: String = "UAInAppMessageFullScreenStyle.plist"

    static var defaultValues: FullScreenTheme {
        let defaultPadding = EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24)
        let defaultHeaderPadding = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        let defaultBodyPadding = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        let defaultMediaPadding = EdgeInsets(top: 0, leading: -24, bottom: 0, trailing: -24)
        let defaultButtonPadding = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

        return FullScreenTheme(
            additionalPadding: defaultPadding,
            headerTheme: TextTheme(letterSpacing: 0,
                                   lineSpacing: 0,
                                   additionalPadding: defaultHeaderPadding),
            bodyTheme: TextTheme(letterSpacing: 0,
                                 lineSpacing: 0,
                                 additionalPadding: defaultBodyPadding),
            mediaTheme: MediaTheme(additionalPadding: defaultMediaPadding),
            buttonTheme: ButtonTheme(buttonHeight: Theme.defaultButtonHeight,
                                     stackedButtonSpacing: Theme.defaultStackedButtonSpacing,
                                     separatedButtonSpacing: Theme.defaultSeparatedButtonSpacing,
                                     additionalPadding: defaultButtonPadding),
            dismissIconResource: "xmark"
        )
    }
}

extension HTMLTheme: ThemeDefaultable {
    static let defaultPlistName: String = "UAInAppMessageHTMLStyle.plist"

    static var defaultValues: HTMLTheme {
        let defaultPadding = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

        return HTMLTheme(hideDismissIcon: false,
                         additionalPadding: defaultPadding,
                         dismissIconResource: "xMark",
                         maxWidth: 400,
                         maxHeight: 500)
    }
}