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

// MARK: - Theme

// Should be a struct instead?
public enum Theme: Codable, Sendable, Hashable, Identifiable, CaseIterable {
  public var id: Tagged<Self, Int> { .init(hashValue) }

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
      #if os(macOS)
      .init(
        red: 0x1A / 0xFF,
        green: 0x1A / 0xFF,
        blue: 0x1A / 0xFF
      )
      #else
      .init(
        red: 0x10 / 0xFF,
        green: 0x10 / 0xFF,
        blue: 0x10 / 0xFF
      )
      #endif
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

extension Theme {
  public static let pastelGreen = Color(hue: 138 / 360, saturation: 0.33, brightness: 0.63)
  public static let pastelBlue = Color(hue: 178 / 360, saturation: 0.39, brightness: 0.7)
  public static let pastelOrange = Color(hue: 27 / 360, saturation: 0.41, brightness: 0.69)
}
