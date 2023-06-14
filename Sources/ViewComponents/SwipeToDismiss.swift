//
//  File.swift
//
//
//  Created by ErrorErrorError on 5/12/23.
//
//

import Foundation
import SwiftUI

// MARK: - SwipeToDismissModifier

@MainActor
public struct SwipeToDismissModifier: ViewModifier {
    var onDismiss: () -> Void

    @State
    private var didDismiss = false

    @State
    private var offset: CGSize = .zero

    @GestureState
    private var isDragActive = false

    @MainActor
    public func body(content: Content) -> some View {
        content
            .offset(x: offset.width)
            .animation(.interactiveSpring(), value: offset != .zero)
            .highPriorityGesture(
                DragGesture(minimumDistance: 25, coordinateSpace: .global)
                    .updating($isDragActive) { _, state, _ in
                        state = true
                    }
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
                    .onEnded { _ in
                        if offset.width > 50 {
                            didDismiss = true
                            onDismiss()
                        } else {
                            offset = .zero
                        }
                    }
            )
            .onChange(of: isDragActive) { newValue in
                /// Handles cancelled gestures
                if !newValue, offset != .zero, !didDismiss {
                    offset = .zero
                }
            }
    }
}

public extension View {
    @MainActor
    func screenDismissed(_ onDismiss: @escaping () -> Void) -> some View {
        modifier(SwipeToDismissModifier(onDismiss: onDismiss))
    }
}
