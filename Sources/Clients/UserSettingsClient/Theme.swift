//
//  Theme.swift
//
//
//  Created by ErrorErrorError on 10/11/23.
//  
//

import Foundation
import SwiftUI
import Tagged
import ViewComponents

public enum Theme: Codable, Sendable, Hashable, Identifiable, CaseIterable {
    public var id: Tagged<Self, Int> { .init(self.hashValue) }

    case automatic
    case light
    case dark

    public var name: LocalizedStringKey {
        switch self {
        case .automatic:
            "Auto"
        case .light:
            "Light"
        case .dark:
            "Dark"
        }
    }

    public var textColor: Color {
        switch self {
        case .automatic:
            .init(
                light: Self.light.textColor,
                dark: Self.dark.textColor
            )
        case .light:
            .init(white: 0.0)
        case .dark:
            .init(white: 1.0)
        }
    }

    public var backgroundColor: Color {
        switch self {
        case .automatic:
            .init(
                light: Self.light.backgroundColor,
                dark: Self.dark.backgroundColor
            )
        case .light:
            .init(
                red: 0xF7 / 0xFF,
                green: 0xF7 / 0xFF,
                blue: 0xF7 / 0xFF
            )
        case .dark:
            .init(
                red: 0x0A / 0xFF,
                green: 0x0A / 0xFF,
                blue: 0x0A / 0xFF
            )
        }
    }

    public var overBackgroundColor: Color {
        switch self {
        case .automatic:
            .init(
                light: Self.light.overBackgroundColor,
                dark: Self.dark.overBackgroundColor
            )
        case .light:
                .init(white: 1.0)
        case .dark:
            .init(white: 0.12)
        }
    }

    public var colorScheme: ColorScheme? {
        switch self {
        case .automatic:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}
