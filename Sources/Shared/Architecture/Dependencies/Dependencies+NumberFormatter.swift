//
//  Dependencies+NumberFormatter.swift
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

extension DependencyValues {
  public var numberFormatter: NumberFormatter {
    get { self[NumberFormatterKey.self] }
    set { self[NumberFormatterKey.self] = newValue }
  }
}

extension Double {
  public var withoutTrailingZeroes: String {
    @Dependency(\.numberFormatter) var formatter

    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 2

    let number = NSNumber(value: self)
    return formatter.string(from: number) ?? description
  }
}
