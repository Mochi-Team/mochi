//
//  File.swift
//  
//
//  Created by ErrorErrorError on 10/10/23.
//  
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct ThemeModifier: ViewModifier {
    @Dependency(\.userSettings) var userSettingsClient

    @StateObject var viewModel: ThemeManager = .init()

    func body(content: Content) -> some View {
        content
            .task {
                for await theme in userSettingsClient.theme {
                    viewModel.apply(theme: theme)
                }
            }
            .environmentObject(viewModel)
            .background(viewModel.theme.backgroundColor.ignoresSafeArea(.all, edges: .all))
    }
}

@dynamicMemberLookup
public class ThemeManager: ObservableObject {
    @Published var theme: Theme = .default

    public subscript<Value>(dynamicMember dynamicMember: KeyPath<Theme, Value>) -> Value {
        theme[keyPath: dynamicMember]
    }

    func apply(theme: Theme) {
        self.theme = theme
    }
}

public extension View {
    func themable() -> some View {
        modifier(ThemeModifier())
    }
}
