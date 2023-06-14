//
//  File.swift
//
//
//  Created by ErrorErrorError on 4/23/23.
//
//

import Foundation
import SwiftUI

// MARK: - Theme

public struct Theme: Hashable {
    public let primaryColor: Color = .green
}

extension EnvironmentValues {
    private struct ThemeKey: EnvironmentKey {
        static var defaultValue: Theme = .init()
    }

    public var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
