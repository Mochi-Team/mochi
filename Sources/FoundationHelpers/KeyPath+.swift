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

public func ?? <T, V>(keyPath: KeyPath<T, V?>, rhs: V) -> (T) -> V {
    { $0[keyPath: keyPath] ?? rhs }
}

public extension Sequence {
    func sorted<Value: Comparable>(by keyPath: KeyPath<Element, Value>) -> [Element] {
        sorted { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
    }
}

infix operator |>
public func |> <T, L: Sequence, V: Equatable>(keyPath: KeyPath<T, V>, _ into: L) -> (T) -> Bool where V == L.Element {
    { into.contains($0[keyPath: keyPath]) }
}

infix operator !|>
public func !|> <T, L: Sequence, V: Equatable>(keyPath: KeyPath<T, V>, _ into: L) -> (T) -> Bool where V == L.Element {
    { !into.contains($0[keyPath: keyPath]) }
}
