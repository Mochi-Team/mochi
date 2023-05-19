//
//  File.swift
//  
//
//  Created by ErrorErrorError on 5/18/23.
//  
//

import Foundation

// swiftlint:disable type_name
protocol _OptionalType {
    func wrappedType() -> Any.Type
}

extension Optional: _OptionalType {
    func wrappedType() -> Any.Type {
        Wrapped.self
    }
}
