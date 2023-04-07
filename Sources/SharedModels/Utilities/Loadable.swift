//
//  Loadable.swift
//
//
//  Created by ErrorErrorError on 4/5/23.
//
//

import Foundation

public enum Loadable<T> {
    case loading
    case loaded(T)
    case failed
}

public extension Loadable {
    func map<V>(_ block: @escaping (T) -> V) -> Loadable<V> {
        switch self {
        case .loading:
            return .loading
        case .loaded(let t):
            return .loaded(block(t))
        case .failed:
            return .failed
        }
    }
}

extension Loadable: Equatable where T: Equatable {}
extension Loadable: Hashable where T: Hashable {}

extension Loadable: Comparable where T: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loaded):
            return true
        case (.loading, .failed):
            return true
        case let (.loaded(lhsValue), .loaded(rhsValue)):
            return lhsValue < rhsValue
        default:
            return false
        }
    }
}
