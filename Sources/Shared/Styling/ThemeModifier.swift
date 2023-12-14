//
//  ThemeModifier.swift
//
//
//  Created by ErrorErrorError on 10/11/23.
//
//

import ComposableArchitecture
import Foundation
import SwiftUI
import UserSettingsClient

// MARK: - ThemeModifier

private struct ThemeModifier: ViewModifier {
  @Dependency(\.userSettings)
  var userSettingsClient

  @State
  var currentTheme: Theme = ThemeKey.defaultValue

  func body(content: Content) -> some View {
    content
      .environment(\.theme, currentTheme)
      .preferredColorScheme(currentTheme.colorScheme)
      .background(currentTheme.backgroundColor.ignoresSafeArea(.all, edges: .all))
      .animation(.easeInOut, value: currentTheme)
      .task {
        for await theme in userSettingsClient.theme {
          currentTheme = theme
        }
      }
  }
}

// MARK: - ThemeKey

private struct ThemeKey: EnvironmentKey {
  static var defaultValue: Theme {
    @Dependency(\.userSettings)
    var userSettingsClient
    return userSettingsClient.theme
  }
}

extension EnvironmentValues {
  public var theme: Theme {
    get { self[ThemeKey.self] }
    set { self[ThemeKey.self] = newValue }
  }
}

extension View {
  public func themeable() -> some View {
    modifier(ThemeModifier())
  }
}
