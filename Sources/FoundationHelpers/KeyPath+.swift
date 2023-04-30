//
//  File.swift
//  
//
//  Created by ErrorErrorError on 4/21/23.
//  
//

// swiftlint:disable static_operator

import Foundation

public prefix func ! <T>(keyPath: KeyPath<T, Bool>) -> (T) -> Bool  {
    { !$0[keyPath: keyPath] }
}

public func == <T, V: Equatable>(lhs: KeyPath<T, V>, rhs: V) -> (T) -> Bool {
    { $0[keyPath: lhs] == rhs }
}
