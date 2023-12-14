//
//  SheetDetent.swift
//
//
//  Created by ErrorErrorError on 10/5/23.
//
//

import Foundation
import SwiftUI

public struct SheetDetent<Content: View>: View {
  let initialHeight: CGFloat
  let content: () -> Content

  @Binding
  private var isExpanded: Bool

  @GestureState
  private var offsetHeight = 0.0

  public init(
    isExpanded: Binding<Bool>,
    initialHeight: CGFloat = 0.0,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self._isExpanded = isExpanded
    self.initialHeight = initialHeight
    self.content = content
  }

  public var body: some View {
    GeometryReader { proxy in
      content()
        .background {
          RoundedCorners(topRadius: 16)
            .style(
              withStroke: Color.gray.opacity(0.2),
              lineWidth: 1,
              fill: .regularMaterial
            )
            .ignoresSafeArea(.all, edges: .bottom)
        }
        .offset(x: 0, y: isExpanded ? 0 : proxy.size.height - initialHeight)
        .offset(y: offsetHeight)
        .highPriorityGesture(
          DragGesture()
            .updating($offsetHeight) { value, state, _ in
              let translation = value.translation.height
              let maxHeight = proxy.size.height - initialHeight
              let dragCoefficient = 4.0

              if isExpanded {
                if translation > 0, translation < maxHeight {
                  state = translation
                } else if translation > 0 {
                  state = maxHeight + (dragCoefficient * log((translation - maxHeight) / dragCoefficient))
                } else if translation < 0 {
                  state = -(dragCoefficient * log(abs(translation) / dragCoefficient))
                }
              } else {
                if translation < 0, -maxHeight < translation {
                  state = translation
                } else if translation < 0 {
                  state = -maxHeight - (dragCoefficient * log(abs(maxHeight + translation) / dragCoefficient))
                } else if translation > 0 {
                  state = (dragCoefficient * log(translation / dragCoefficient))
                }
              }
            }
            .onEnded { value in
              let height = value.translation.height
              let heightVelocity = value.predictedEndTranslation.height
              if isExpanded {
                if height > (proxy.size.height / 2) || heightVelocity > (proxy.size.height / 2) {
                  isExpanded = false
                }
              } else {
                if height < -(proxy.size.height / 2) || heightVelocity < -(proxy.size.height / 2) {
                  isExpanded = true
                }
              }
            }
        )
        .animation(.spring(), value: isExpanded)
        .animation(.spring(), value: offsetHeight == 0)
    }
  }
}
