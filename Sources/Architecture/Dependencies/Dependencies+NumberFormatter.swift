//
//  Dependencies+DateFormatter.swift
//
//
//  Created by ErrorErrorError on 5/2/23.
//
//

import ComposableArchitecture
import Foundation

// MARK: - NumberFormatterKey

public struct NumberFormatterKey: DependencyKey {
    public static let liveValue = NumberFormatter()
}

public extension DependencyValues {
    var numberFormatter: NumberFormatter {
        get { self[NumberFormatterKey.self] }
        set { self[NumberFormatterKey.self] = newValue }
    }
}

public extension Double {
    var withoutTrailingZeroes: String {
        @Dependency(\.numberFormatter)
        var formatter

        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2

        let number = NSNumber(value: self)
        return formatter.string(from: number) ?? description
    }
}
