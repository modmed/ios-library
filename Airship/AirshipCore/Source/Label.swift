/* Copyright Airship and Contributors */

import Foundation
import SwiftUI

/// Text/Label view

struct Label: View {
    let info: ThomasViewInfo.Label

    /// View constraints.
    let constraints: ViewConstraints


    @Environment(\.colorScheme) var colorScheme

    @available(iOS 15, tvOS 15, watchOS 8, *)
    private var markdownText: Text {
        get throws {
            var text = try AttributedString(
                markdown: self.info.properties.text,
                options: .init(
                    interpretedSyntax: .inlineOnlyPreservingWhitespace
                )
            )

            let anchorAppearance = self.info.properties.markdown?.appearance?.anchor
            let anchorColor = anchorAppearance?.color?.toColor(self.colorScheme)
            // Currently we only support underlined styles
            let underline = anchorAppearance?.styles?.contains(.underlined) ?? false

            text.runs.filter { run in
                run.link != nil
            }.forEach { run in
                text[run.range].foregroundColor = anchorColor
                if underline {
                    text[run.range].underlineStyle = .single
                }
            }

            return Text(text)
        }
    }

    private var text: Text {
        guard 
            self.info.properties.markdown?.disabled != true,
            #available(iOS 15, tvOS 15, watchOS 8, *)
        else {
            return Text(verbatim: self.info.properties.text)
        }

        do {
            return try markdownText
        } catch {
            AirshipLogger.error("Failed to parse markdown text \(error) text \(self.info.properties.text)")
            return Text(verbatim: self.info.properties.text)
        }
    }

    var body: some View {
        self.text
            .textAppearance(self.info.properties.textAppearance)
            .truncationMode(.tail)
            .constraints(
                constraints,
                alignment: self.info.properties.textAppearance.alignment?
                    .toFrameAlignment()
                    ?? Alignment.center
            )
            .fixedSize(
                horizontal: false,
                vertical: self.constraints.height == nil
            )
            .thomasCommon(self.info)
            .accessible(self.info.accessible)
            .accessibilityRole(self.info.properties.accessibilityRole)
    }
}

extension ThomasTextAppearance.TextAlignement {
    func toFrameAlignment() -> Alignment {
        switch self {
        case .start:
            return Alignment.leading
        case .end:
            return Alignment.trailing
        case .center:
            return Alignment.center
        }
    }

    func toSwiftTextAlignment() -> SwiftUI.TextAlignment {
        switch self {
        case .start:
            return SwiftUI.TextAlignment.leading
        case .end:
            return SwiftUI.TextAlignment.trailing
        case .center:
            return SwiftUI.TextAlignment.center
        }
    }

    func toNSTextAlignment() -> NSTextAlignment {
        switch self {
        case .start:
            return .left
        case .end:
            return .right
        case .center:
            return .center
        }
    }
}

extension View {
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    fileprivate func headingLevel(_ int: Int) -> AccessibilityHeadingLevel {
        switch int {
        case 1:
            return .h1
        case 2:
            return .h2
        case 3:
            return .h1
        case 4:
            return .h4
        case 5:
            return .h5
        case 6:
            return .h6
        default:
            return .unspecified
        }
    }

    @ViewBuilder
    fileprivate func accessibilityRole(_ role: ThomasViewInfo.Label.AccessibilityRole?) -> some View  {
        switch role {
        case .heading(let level):
            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                self.accessibilityAddTraits(.isHeader)
                    .accessibilityHeading(headingLevel(level))
             } else {
                 self.accessibilityAddTraits(.isHeader)
             }
        case .none:
            self
        }
    }

}
