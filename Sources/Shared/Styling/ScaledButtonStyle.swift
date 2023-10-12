//
//  ScaledButtonStyle.swift
//
//
//  Created by ErrorErrorError on 10/12/23.
//  
//

import Foundation
import SwiftUI

public struct ScaleButtonStyle: ButtonStyle {
    public func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ScaleButtonStyle {

    /// A button style that doesn't style or decorate its content while idle,
    /// but may apply a visual effect to indicate the pressed, focused, or
    /// enabled state of the button.
    ///
    /// To apply this style to a button, or to a view that contains buttons, use
    /// the ``View/buttonStyle(_:)-66fbx`` modifier.
    public static var scaled: ScaleButtonStyle { .init() }
}
