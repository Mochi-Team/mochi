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

public extension Color {
    static let theme = Theme()
}

public struct Theme: Hashable {
    public let primaryColor: Color = .green
    public let backgroundColor: Color = .init("BackgroundColor")
}
