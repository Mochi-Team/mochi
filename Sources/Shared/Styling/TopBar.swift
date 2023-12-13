//
//  TopBar.swift
//
//
//  Created by ErrorErrorError on 4/25/23.
//
//

import Foundation
import SwiftUI
import UserSettingsClient
import ViewComponents

public extension ButtonStyle where Self == MaterialToolbarItemButtonStyle {
    static var materialToolbarItem: MaterialToolbarItemButtonStyle { .init() }
}

// MARK: - MaterialToolbarItemButtonStyle

public struct MaterialToolbarItemButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .materialToolbarItemStyle()
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(), value: configuration.isPressed)
    }
}

public extension MenuStyle where Self == MaterialToolbarButtonMenuStyle {
    static var materialToolbarItem: MaterialToolbarButtonMenuStyle { .init() }
}

// MARK: - MaterialToolbarButtonMenuStyle

public struct MaterialToolbarButtonMenuStyle: MenuStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        Menu(configuration)
            .materialToolbarItemStyle()
    }
}

private struct MaterialToolbarItemStyle: ViewModifier {
    @ScaledMetric
    var fontSize = 12

    @ScaledMetric
    var viewSize = 28

    func body(content: Content) -> some View {
        Circle()
            .style(withStroke: .gray.opacity(0.16), fill: .regularMaterial)
            .overlay {
                content
                    .foregroundColor(.label)
                    .font(.system(size: fontSize, weight: .bold, design: .default))
            }
            .frame(width: viewSize, height: viewSize, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            .contentShape(Rectangle())
    }
}

public extension View {
    func materialToolbarItemStyle() -> some View {
        self.modifier(MaterialToolbarItemStyle())
    }
}
