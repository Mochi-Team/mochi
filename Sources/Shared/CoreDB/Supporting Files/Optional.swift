//
//  Optional.swift
//
//
//  Created by ErrorErrorError on 5/18/23.
//
//

import Foundation

// MARK: - OpaqueOptional

protocol OpaqueOptional {
  func wrappedType() -> Any.Type
  var isNil: Bool { get }
}

// MARK: - Optional + OpaqueOptional

extension Optional: OpaqueOptional {
  func wrappedType() -> Any.Type { Wrapped.self }
  var isNil: Bool { self == nil }
}
