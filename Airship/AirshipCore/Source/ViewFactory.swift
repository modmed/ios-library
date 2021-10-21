/* Copyright Airship and Contributors */

import Foundation
import SwiftUI

/// View factory. Inflates views based on type.
@available(iOS 13.0.0, tvOS 13.0, *)
struct ViewFactory {
    @ViewBuilder
    static func createView(model: BaseViewModel, constraints: ViewConstraints) -> some View {
        switch (model) {
        case let containerModel as ContainerModel:
            Container(model: containerModel, constraints: constraints)
        case let linearLayoutModel as LinearLayoutModel:
            LinearLayout(model: linearLayoutModel, constraints: constraints)
        case let scrollLayoutModel as ScrollLayoutModel:
            ScrollLayout(model: scrollLayoutModel, constraints: constraints)
        case let labelModel as LabelModel:
            Label(model: labelModel, constraints: constraints)
        case let buttonModel as ButtonModel:
            AirshipButton(model: buttonModel, constraints: constraints)
        default:
            Text("\(model.type.rawValue) not supported")
        }
    }
}
