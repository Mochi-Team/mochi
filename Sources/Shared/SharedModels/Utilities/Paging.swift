//
//  Paging.swift
//
//
//  Created by ErrorErrorError on 4/18/23.
//
//

import Foundation
import Tagged

// MARK: - PagingID

public enum _Paging {}
public typealias PagingID = Tagged<_Paging, String>

// MARK: - Paging

public struct Paging<T>: Identifiable {
    public let id: PagingID
    public let previousPage: PagingID?
    public let nextPage: PagingID?
    public let items: [T]

    public init(
        id: PagingID,
        previousPage: PagingID? = nil,
        nextPage: PagingID? = nil,
        items: [T] = []
    ) {
        self.id = id
        self.previousPage = previousPage
        self.nextPage = nextPage
        self.items = items
    }
}

// MARK: Equatable

extension Paging: Equatable where T: Equatable {}

// MARK: Sendable

extension Paging: Sendable where T: Sendable {}

// MARK: Hashable

extension Paging: Hashable where T: Hashable {}

extension Paging: Codable where T: Codable {}

public extension Paging {
    func cast<V>(_: V.Type = V.self) -> Paging<V> {
        .init(
            id: id,
            previousPage: previousPage.flatMap { $0 },
            nextPage: nextPage.flatMap { $0 },
            items: items.compactMap { $0 as? V }
        )
    }

    func map<V>(to value: (T) -> V) -> Paging<V> {
        .init(
            id: id,
            previousPage: previousPage.flatMap { $0 },
            nextPage: nextPage.flatMap { $0 },
            items: items.compactMap(value)
        )
    }
}
