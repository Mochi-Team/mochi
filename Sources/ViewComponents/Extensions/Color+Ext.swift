//
//  File.swift
//  
//
//  Created by ErrorErrorError on 5/21/23.
//  
//

import Foundation
import SwiftUI

public extension Color {
    @Environment(\.colorScheme)
    private static var colorScheme

    var isDark: Bool {
        PlatformColor(self).luminance < 0.5
    }

    static var label: Color {
        .init(.label)
//        return colorScheme == .light ? .black : .white
    }
}

extension Color {
    init(_ platformColor: PlatformColor) {
        #if canImport(UIKit)
        self = .init(uiColor: platformColor)
        #elseif canImport(AppKit)
        self = .init(nsColor: platformColor)
        #endif
    }
}
