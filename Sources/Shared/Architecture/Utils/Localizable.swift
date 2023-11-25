//
//  Localizable.swift
//
//
//  Created by ErrorErrorError on 11/22/23.
//  
//

import Foundation

public protocol Localizable {
    func localized() -> String
}

public extension Localizable where Self: RawRepresentable, Self.RawValue == String {
    func localized() -> String {
        NSLocalizedString(self.rawValue, comment: "")
    }
}
