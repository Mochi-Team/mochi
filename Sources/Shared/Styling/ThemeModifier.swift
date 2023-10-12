//
//  File.swift
//  
//
//  Created by ErrorErrorError on 10/11/23.
//  
//

import ComposableArchitecture
import Foundation
import SwiftUI
import UserSettingsClient

private struct ThemeModifier: ViewModifier {
    @Dependency(\.userSettings) var userSettingsClient

    @State var currentTheme: Theme = ThemeKey.defaultValue

    func body(content: Content) -> some View {
        content
            .task {
                for await theme in userSettingsClient.theme {
                    currentTheme = theme
                }
            }
            .environment(\.theme, currentTheme)
            .preferredColorScheme(currentTheme.colorScheme)
            .background(currentTheme.backgroundColor.ignoresSafeArea(.all, edges: .all))
            .animation(.easeInOut, value: currentTheme)
    }
}

private struct ThemeKey: EnvironmentKey {
    static var defaultValue: Theme {
        @Dependency(\.userSettings) var userSettingsClient
        return userSettingsClient.theme
    }
}

extension EnvironmentValues {
    public var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

public extension View {
    func themable() -> some View {
        modifier(ThemeModifier())
    }
}
