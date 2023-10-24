//
//  PlatformColor+Ext.swift
//
//
//  Created by ErrorErrorError on 5/21/23.
//
//

import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
typealias PlatformColor = NSColor
#endif

extension PlatformColor {
    /// https://www.w3.org/TR/WCAG20/#relativeluminancedef
    var luminance: CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let conversion: (CGFloat) -> CGFloat = { value in
            value <= 0.03928 ? (value / 12.92) : pow((value + 0.055) / 1.055, 2.4)
        }
        return (0.2126 * conversion(red)) + (0.7152 * conversion(green)) + (0.0722 * conversion(blue))
    }

    /// https://www.w3.org/TR/WCAG20/#contrast-ratiodef
    func contrastRatio(to otherColor: PlatformColor) -> CGFloat {
        let ourLuminance = luminance
        let theirLuminance = otherColor.luminance
        let lighterColor = min(ourLuminance, theirLuminance)
        let darkerColor = max(ourLuminance, theirLuminance)
        return 1 / ((lighterColor + 0.05) / (darkerColor + 0.05))
    }
}

extension PlatformColor {
    static func blend(from firstColor: PlatformColor, to secondColor: PlatformColor, amount blendAmount: Double) -> PlatformColor {
        let blendAmount = min(1.0, max(0, blendAmount))

        let components: (PlatformColor) -> [CGFloat] = { color in
            var red: CGFloat = 0.0
            var green: CGFloat = 0.0
            var blue: CGFloat = 0.0
            var alpha: CGFloat = 0.0
            #if canImport(UIKit)
            color.resolvedColor(with: .current)
                .getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            #elseif canImport(AppKit)
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            #endif
            return [red, green, blue, alpha]
        }

        let components1 = components(firstColor)
        let components2 = components(secondColor)

        let red1 = components1[0]
        let red2 = components2[0]

        let green1 = components1[1]
        let green2 = components2[1]

        let blue1 = components1[2]
        let blue2 = components2[2]

        let alpha1 = components1[3]
        let alpha2 = components2[3]

        let red = red1 + (red2 - red1) * blendAmount
        let green = green1 + (green2 - green1) * blendAmount
        let blue = blue1 + (blue2 - blue1) * blendAmount
        let alpha = alpha1 + (alpha2 - alpha1) * blendAmount

        return .init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

public extension Color {
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(light: UIColor(light), dark: UIColor(dark))
        #else
        self.init(light: NSColor(light), dark: NSColor(dark))
        #endif
    }

    #if canImport(UIKit)
    init(light: UIColor, dark: UIColor) {
        #if os(watchOS)
        self.init(uiColor: dark)
        #else
        self.init(uiColor: UIColor(dynamicProvider: { traits in
            switch traits.userInterfaceStyle {
            case .light, .unspecified:
                return light

            case .dark:
                return dark

            @unknown default:
                assertionFailure("Unknown userInterfaceStyle: \(traits.userInterfaceStyle)")
                return light
            }
        }))
        #endif
    }
    #endif

    #if canImport(AppKit)
    init(light: NSColor, dark: NSColor) {
        self.init(nsColor: NSColor(name: nil, dynamicProvider: { colorScheme in
            switch colorScheme.name {
            case .aqua,
                 .vibrantLight,
                 .accessibilityHighContrastAqua,
                 .accessibilityHighContrastVibrantLight:
                return light

            case .darkAqua,
                 .vibrantDark,
                 .accessibilityHighContrastDarkAqua,
                 .accessibilityHighContrastVibrantDark:
                return dark

            default:
                assertionFailure("Unknown appearance: \(colorScheme.name)")
                return light
            }
        }))
    }
    #endif
}
