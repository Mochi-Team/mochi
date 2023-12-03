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

public protocol Localizable {
    var localizable: String { get }
}

public extension Localizable {
    var localized: String {
        @Dependency(\.localizableClient.localize)
        var localize

        return localize(self.localizable)
    }
}

public extension Localizable where Self: RawRepresentable, Self.RawValue == String {
    var localizable: String { self.rawValue }
}

public extension Localizable where Self: CustomStringConvertible {
    var localizable: String { self.description }
}

public extension String {
    init(localizable: String) {
        @Dependency(\.localizableClient.localize)
        var localize

        self = localize(localizable)
    }
}

public extension Text {
    init(localizable: String) {
        @Dependency(\.localizableClient.localize)
        var localize

        self.init(localize(localizable))
    }
}
