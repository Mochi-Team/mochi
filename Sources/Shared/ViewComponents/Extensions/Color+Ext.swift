//
//  Color+Ext.swift
//
//
//  Created by ErrorErrorError on 5/21/23.
//
//

import Foundation
import SwiftUI

public extension Color {
    var isDark: Bool {
        PlatformColor(self).luminance < 0.5
    }

    static var label: Color {
        #if canImport(AppKit)
        .init(PlatformColor.textColor)
        #else
        .init(PlatformColor.label)
        #endif
    }

    static var secondarySystemBackground: Color {
        #if canImport(AppKit)
        .init(PlatformColor.controlBackgroundColor)
        #else
        .init(PlatformColor.secondarySystemBackground)
        #endif
    }
}

public extension Color {
    init(_ platformColor: PlatformColor) {
        #if canImport(UIKit)
        self = .init(uiColor: platformColor)
        #elseif canImport(AppKit)
        self = .init(nsColor: platformColor)
        #endif
    }
}
