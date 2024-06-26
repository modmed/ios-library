/* Copyright Airship and Contributors */

import SwiftUI

#if canImport(AirshipCore)
import AirshipCore
#endif

struct InAppMessageModalView: View {
    @EnvironmentObject var environment: InAppMessageEnvironment
    let displayContent: InAppMessageDisplayContent.Modal

    @Environment(\.orientation) var orientation

    @State
    private var scrollViewContentSize: CGSize = .zero


    private var padding: EdgeInsets {
        environment.theme.modalTheme.additionalPadding
    }

    private var headerTheme: TextTheme {
        environment.theme.modalTheme.headerTheme
    }

    private var bodyTheme: TextTheme {
        environment.theme.modalTheme.bodyTheme
    }

    private var mediaTheme: MediaTheme {
        environment.theme.modalTheme.mediaTheme
    }

    private var dismissIconResource: String {
        environment.theme.modalTheme.dismissIconResource
    }

    private var maxHeight: CGFloat {
        CGFloat(environment.theme.modalTheme.maxHeight)
    }

    private var maxWidth: CGFloat {
        CGFloat(environment.theme.modalTheme.maxWidth)
    }

    @ViewBuilder
    private var headerView: some View {
        if let heading = displayContent.heading {
            TextView(textInfo: heading, textTheme:headerTheme)
                .applyAlignment(placement: displayContent.heading?.alignment ?? .left)
        }
    }

    @ViewBuilder
    private var bodyView: some View {
        if let body = displayContent.body {
            TextView(textInfo: body, textTheme:bodyTheme)
                .applyAlignment(placement: displayContent.body?.alignment ?? .left)
        }
    }

    @ViewBuilder
    private var mediaView: some View {
        if let media = displayContent.media {
            MediaView(mediaInfo: media, mediaTheme: mediaTheme, imageLoader: environment.imageLoader)
                .applyMediaTheme(mediaTheme)
                .padding(.horizontal, -mediaTheme.additionalPadding.leading).padding(mediaTheme.additionalPadding)
        }
    }

    @ViewBuilder
    private var buttonsView: some View {
        if let buttons = displayContent.buttons, !buttons.isEmpty {
            ButtonGroup(layout: displayContent.buttonLayoutType ?? .stacked,
                        buttons: buttons)
            .environmentObject(environment)
        }
    }

    @ViewBuilder
    private var footerButton: some View {
        if let footer = displayContent.footer {
            ButtonView(buttonInfo: footer)
                .frame(height:Theme.defaultFooterHeight)
                .environmentObject(environment)
        }
    }

    #if os(iOS)
    private var orientationChangePublisher = NotificationCenter.default
        .publisher(for: UIDevice.orientationDidChangeNotification)
        .makeConnectable()
        .autoconnect()
    #endif

    init(displayContent: InAppMessageDisplayContent.Modal) {
        self.displayContent = displayContent
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing:0) {
            ScrollView {
                VStack(spacing:24) {
                    switch displayContent.template {
                    case .headerMediaBody:
                        headerView
                        mediaView
                        bodyView
                    case .headerBodyMedia:
                        headerView
                        bodyView
                        mediaView
                    case .mediaHeaderBody, .none: /// None should never be hit
                        mediaView.padding(.top, -padding.top) /// Remove top padding when media is on top
                        headerView
                        bodyView
                    }
                }
                .padding(padding)
                .background(
                    GeometryReader { geo -> Color in
                        DispatchQueue.main.async {
                            if scrollViewContentSize != geo.size {
                                if case .mediaHeaderBody = displayContent.template {
                                    scrollViewContentSize = CGSize(width: geo.size.width, height: geo.size.height - padding.top)
                                } else {
                                    scrollViewContentSize = geo.size
                                }
                            }
                        }
                        return Color.clear
                    }
                )
            }
            .frame(maxHeight: scrollViewContentSize.height)

            VStack(spacing:24) {
                buttonsView
                footerButton
            }
            .padding(padding)
        }
    }

    var body: some View {
        content
        .addCloseButton(
            dismissButtonColor: displayContent.dismissButtonColor?.color ?? Color.white,
            dismissIconResource: dismissIconResource,
            circleColor: .tappableClear, /// Probably should just do this everywhere and remove circleColor entirely
            onUserDismissed: { environment.onUserDismissed() }
        )
        .background(displayContent.backgroundColor?.color ?? Color.black)
        .cornerRadius(displayContent.borderRadius ?? 0)
        .parentClampingResize(maxWidth: maxWidth, maxHeight: maxHeight)
        .padding(padding)
        .addBackground(color: .shadowColor)
        .onAppear {
            self.environment.onAppear()
        }
    }
}
