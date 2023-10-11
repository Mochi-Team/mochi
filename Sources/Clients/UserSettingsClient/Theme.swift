//
//  Theme.swift
//
//
//  Created by ErrorErrorError on 10/11/23.
//  
//

import Foundation
import Tagged
import SwiftUI
import ViewComponents

public enum Theme: Codable, Sendable, Hashable, Identifiable, CaseIterable {
    public var id: Tagged<Self, Int> { .init(self.hashValue) }

    case `default`
    case bruh

    public var name: String {
        switch self {
        case .default:
            "Default"
        case .bruh:
            "Bruh"
        }
    }

    public var primaryColor: Color { .green }

    public var textColor: Color {
        switch self {
        case .`default`:
            return .init(
                light: .init(white: 0.0),
                dark: .init(white: 1.0)
            )
        case .bruh:
            return .red
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
        case .bruh:
            return .blue
        }
    }
}
