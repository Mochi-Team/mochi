//
//  Loadable.swift
//
//
//  Created by ErrorErrorError on 4/5/23.
//
//

import Foundation

public enum Loadable<T, E> {
    case pending
    case loading
    case loaded(T)
    case failed(E)

    public var finished: Bool {
        switch self {
        case .pending, .loading:
            return false
        default:
            return true
        }
    }

    public var value: T? {
        if case let .loaded(value) = self {
            return value
        }
        return nil
    }

    public var error: E? {
        if case let .failed(error) = self {
            return error
        }
        return nil
    }
}

public extension Loadable {
    func mapValue<V>(_ block: @escaping (T) -> V) -> Loadable<V, E> {
        switch self {
        case .pending:
            return .pending
        case .loading:
            return .loading
        case .loaded(let t):
            return .loaded(block(t))
        case let .failed(e):
            return .failed(e)
        }
    }

    func mapError<V>(_ block: @escaping (E) -> V) -> Loadable<T, V> {
        switch self {
        case .pending:
            return .pending
        case .loading:
            return .loading
        case .loaded(let t):
            return .loaded(t)
        case let .failed(e):
            return .failed(block(e))
        }
    }
}

extension Loadable: Sendable where T: Sendable, E: Sendable {}
extension Loadable: Equatable where T: Equatable, E: Equatable {}
extension Loadable: Hashable where T: Hashable, E: Hashable {}

extension Loadable: Comparable where T: Comparable, E: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.pending, .loading):
            return true
        case (.pending, .loaded):
            return true
        case (.pending, .failed):
            return true
        case (.loading, .loaded):
            return true
        case (.loading, .failed):
            return true
        case (.loaded, .failed):
            return true
        case let (.loaded(lhsValue), .loaded(rhsValue)):
            return lhsValue < rhsValue
        case let (.failed(lhsValue), .failed(rhsValue)):
            return lhsValue < rhsValue
        default:
            return false
        }
    }
}
