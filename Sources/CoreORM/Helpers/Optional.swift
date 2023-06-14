//
//  File.swift
//
//
//  Created by ErrorErrorError on 5/18/23.
//
//

import Foundation

// MARK: - _OptionalType

// swiftlint:disable type_name
protocol _OptionalType {
    func wrappedType() -> Any.Type
}

// MARK: - Optional + _OptionalType

extension Optional: _OptionalType {
    func wrappedType() -> Any.Type {
        Wrapped.self
    }
}
