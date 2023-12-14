//
//  Color+Ext.swift
//
//
//  Created by ErrorErrorError on 5/21/23.
//
//

import Foundation
import SwiftUI

extension Color {
  public var isDark: Bool {
    PlatformColor(self).luminance < 0.5
  }

  public static var label: Color {
    #if canImport(AppKit)
    .init(PlatformColor.textColor)
    #else
    .init(PlatformColor.label)
    #endif
  }

  public static var secondarySystemBackground: Color {
    #if canImport(AppKit)
    .init(PlatformColor.controlBackgroundColor)
    #else
    .init(PlatformColor.secondarySystemBackground)
    #endif
  }
}

extension Color {
  public init(_ platformColor: PlatformColor) {
    #if canImport(UIKit)
    self = .init(uiColor: platformColor)
    #elseif canImport(AppKit)
    self = .init(nsColor: platformColor)
    #endif
  }
}
