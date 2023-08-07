//
//  File.swift
//
//
//  Created by ErrorErrorError on 5/21/23.
//
//

import Foundation
import SwiftUI

#if os(iOS)
public extension Color {
    var isDark: Bool {
        PlatformColor(self).luminance < 0.5
    }

    static var label: Color {
        .init(UIColor.label)
//        return colorScheme == .light ? .black : .white
    }
}
#endif

extension Color {
    init(_ platformColor: PlatformColor) {
        #if canImport(UIKit)
        self = .init(uiColor: platformColor)
        #elseif canImport(AppKit)
        self = .init(nsColor: platformColor)
        #endif
    }
}
