//
//  Localizable.swift
//
//
//  Created by ErrorErrorError on 11/22/23.
//
//

import Dependencies
import Foundation
import SwiftUI

// MARK: - Localizable

public protocol Localizable {
  var localizable: String { get }
}

extension Localizable {
  public var localized: String {
    @Dependency(\.localizableClient.localize) var localize

    return localize(localizable)
  }
}

extension Localizable where Self: RawRepresentable, Self.RawValue == String {
  public var localizable: String { rawValue }
}

extension Localizable where Self: CustomStringConvertible {
  public var localizable: String { description }
}

extension String {
  public init(localizable: String) {
    @Dependency(\.localizableClient.localize) var localize

    self = localize(localizable)
  }
}

extension Text {
  public init(localizable: String) {
    @Dependency(\.localizableClient.localize) var localize

    self.init(localize(localizable))
  }
}
