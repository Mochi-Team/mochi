//
//  File.swift
//  
//
//  Created by ErrorErrorError on 5/12/23.
//  
//

import Foundation
import SwiftUI

public struct SwipeToDismissModifier: ViewModifier {
    var onDismiss: () -> Void
    @State
    private var offset: CGSize = .zero

    public func body(content: Content) -> some View {
        content
            .offset(x: offset.width)
            .animation(.interactiveSpring(), value: offset)
            .highPriorityGesture(
                DragGesture()
                    .onChanged { gesture in
                        if gesture.startLocation.x < 50 {
                            if gesture.translation.width > 0 || gesture.predictedEndTranslation.width > 0 {
                                offset = gesture.translation
                            } else {
                                offset = .zero
                            }
                        } else {
                            offset = .zero
                        }
                    }
                    .onEnded { gesture in
                        if gesture.translation.width > 75 || gesture.predictedEndTranslation.width > 75 {
                            onDismiss()
                        } else {
                            offset = .zero
                        }
                    }
            )
    }
}

public extension View {
    func screenDismissed(_ onDismiss: @escaping () -> Void) -> some View {
        self.modifier(SwipeToDismissModifier(onDismiss: onDismiss))
    }
}
