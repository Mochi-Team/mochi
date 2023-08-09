//
//  File.swift
//
//
//  Created by ErrorErrorError on 4/23/23.
//
//

import Dependencies
import Foundation
import SwiftUI
import Tagged

public extension Color {
    static let theme = Theme.default
}

extension EnvironmentValues {
    public var theme: Theme {
        get { self[Theme.self] }
        set { self[Theme.self] = newValue }
    }
}

extension Theme: EnvironmentKey {
    public static var defaultValue: Theme = .default
}

// MARK: - Theme

public enum Theme: Hashable, Identifiable {
    public var id: Tagged<Self, Int> { .init(self.hashValue) }

    case `default`

    public var primaryColor: Color { .green }

    public var textColor: Color {
        switch self {
        case .`default`:
            return .init(
                light: .init(white: 0.0),
                dark: .init(white: 1.0)
            )
        }
    }

    public var backgroundColor: Color {
        switch self {
        case .`default`:
            return Color(
                light: .init(
                    red: 0xFA / 0xFF,
                    green: 0xFA / 0xFF,
                    blue: 0xFA / 0xFF
                ),
                dark: .init(
                    red: 0x0A / 0xFF,
                    green: 0x0A / 0xFF,
                    blue: 0x0A / 0xFF
                )
            )
        }
    }
}
