//
//  Swipable.swift
//  
//
//  Created by ErrorErrorError on 6/27/23.
//  
//

import Foundation
import SwiftUI

private struct SwipeableModifier: ViewModifier {
    let animation: Animation?

    @State
    private var dismissed = false

    func body(content: Content) -> some View {
        if !dismissed {
            content
                .highPriorityGesture(
                    DragGesture()
                        .onEnded { _ in
                            withAnimation(animation) {
                                dismissed = true
                            }
                        }
                )
        }
    }
}

public extension View {
    func swipeable(_ animation: Animation? = nil) -> some View {
        modifier(SwipeableModifier(animation: animation))
    }
}
