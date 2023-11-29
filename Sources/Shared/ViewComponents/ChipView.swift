//
//  ChipView.swift
//
//
//  Created by ErrorErrorError on 7/23/23.
//
//

import Foundation
import SwiftUI

// MARK: - ChipView

public struct ChipView<Accessory: View, Background: ShapeStyle>: View {
    let accessory: () -> Accessory
    let background: () -> Background

    public init(
        @ViewBuilder accessory: @escaping () -> Accessory,
        background: @escaping () -> Background
    ) {
        self.accessory = accessory
        self.background = background
    }

    public var body: some View {
        accessory()
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(background(), in: Capsule(style: .continuous))
    }

    public func background<S: ShapeStyle>(_ style: S) -> ChipView<Accessory, S> {
        .init(accessory: accessory) { style }
    }
}

public extension ChipView {
    init(text: String, material: Material = .ultraThinMaterial) where Accessory == Text, Background == Material {
        self.init {
            Text(text)
        } background: {
            material
        }
    }
}

public extension ChipView {
    init(systemName: String, material: Material = .ultraThinMaterial) where Accessory == Image, Background == Material {
        self.init {
            Image(systemName: systemName)
        } background: {
            material
        }
    }
}
