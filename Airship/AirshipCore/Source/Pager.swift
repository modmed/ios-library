import Foundation
import SwiftUI

@available(iOS 13.0.0, tvOS 13.0, *)
struct Pager : View {
    private static let minDragWidth: CGFloat = 10
    @EnvironmentObject var pagerState: PagerState
    @EnvironmentObject var context: ThomasContext

    let model: PagerModel
    let constraints: ViewConstraints
    
    @State var lastIndex = -1

    @ViewBuilder
    var body: some View {
        let index = Binding<Int>(
            get: { self.pagerState.index },
            set: { self.pagerState.index = $0 }
        )

        let items = self.model.items
        if #available(iOS 14.0.0, tvOS 14.0, *), self.model.disableSwipe != true {
            TabView(selection: index) {
                ForEach(0..<items.count, id: \.self) { i in
                    ViewFactory.createView(model: items[index.wrappedValue],
                                           constraints: self.constraints)
                        .tag(i)
                        .onAppear {
                            reportPage(i)
                        }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .constraints(self.constraints)
            .onAppear {
                pagerState.pages = self.model.items.count
            }
        } else {
            VStack {
                let index = index.wrappedValue
                ViewFactory.createView(model: items[index],
                                       constraints: self.constraints)
                    .onAppear {
                        reportPage(index)
                    }
            }
            .applyIf(self.model.disableSwipe != false) { view in
                #if !os(tvOS)
                view.highPriorityGesture(DragGesture().onEnded { drag in
                    let dragWidth = drag.translation.width
                    if (dragWidth > Pager.minDragWidth) {
                        index.wrappedValue = max(index.wrappedValue - 1, 0)
                    } else if (dragWidth < Pager.minDragWidth) {
                        index.wrappedValue = min(index.wrappedValue + 1, items.count - 1)
                    }
                })
                #else
                view
                #endif
            }
            .constraints(self.constraints)
            .onAppear {
                pagerState.pages = self.model.items.count
            }
        }
    }
    
    private func reportPage(_ index: Int) {
        if (self.lastIndex != index) {
            self.context.eventHandler.onPageView(pagerIdentifier: self.model.identifier,
                                                 pageIndex: index,
                                                 pageCount: self.model.items.count)
            self.lastIndex = index
        }
    }
}
     