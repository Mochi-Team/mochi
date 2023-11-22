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

// MARK: BasePaging

public struct BasePaging<T> {
    public let id: PagingID
    public let previousPage: PagingID?
    public let nextPage: PagingID?
    public let title: String?
    public let items: T

    public init(
        id: PagingID,
        previousPage: PagingID? = nil,
        nextPage: PagingID? = nil,
        title: String? = nil,
        items: T
    ) {
        self.id = id
        self.previousPage = previousPage
        self.nextPage = nextPage
        self.title = title
        self.items = items
    }
}

// MARK: - Paging

public typealias Paging<T> = BasePaging<[T]>

// MARK: - LoadablePaging

public typealias LoadablePaging<T> = BasePaging<Loadable<[T]>>

// MARK: - OptionalPaging

public typealias OptionalPaging<T> = BasePaging<[T]?>

// MARK: Identifable

extension BasePaging: Identifiable {}

// MARK: Equatable

extension BasePaging: Equatable where T: Equatable {}

// MARK: Sendable

extension BasePaging: Sendable where T: Sendable {}

// MARK: Hashable

extension BasePaging: Hashable where T: Hashable {}

// MARK: Codable

extension BasePaging: Codable where T: Codable {}

public extension BasePaging where T: Sequence {
    func cast<V>(_: V.Type = V.self) -> Paging<V> {
        .init(
            id: id,
            previousPage: previousPage.flatMap { $0 },
            nextPage: nextPage.flatMap { $0 },
            items: items.compactMap { $0 as? V }
        )
    }

    func map<V>(to value: (T.Element) -> V) -> Paging<V> {
        .init(
            id: id,
            previousPage: previousPage.flatMap { $0 },
            nextPage: nextPage.flatMap { $0 },
            items: items.compactMap(value)
        )
    }
}

//    // MARK: - LoadablePaging
//
//    public struct LoadablePaging<T>: BasePaging {
//        public let id: PagingID
//        public let previousPage: PagingID?
//        public let nextPage: PagingID?
//        public let items: [T]
//
//        public init(
//            id: PagingID,
//            previousPage: PagingID? = nil,
//            nextPage: PagingID? = nil,
//            items: [T]
//        ) {
//            self.id = id
//            self.previousPage = previousPage
//            self.nextPage = nextPage
//            self.items = items
//        }
//    }
//
//    // MARK: Equatable
//
//    extension LoadablePaging: Equatable where T: Equatable {}
//
//    // MARK: Sendable
//
//    extension LoadablePaging: Sendable where T: Sendable {}
//
//    // MARK: Hashable
//
//    extension LoadablePaging: Hashable where T: Hashable {}
//
//    // MARK: Codable
//
//    extension LoadablePaging: Codable where T: Codable {}
//
//    public extension LoadablePaging {
//        func cast<V>(_: V.Type = V.self) -> LoadablePaging<V> {
//            .init(
//                id: id,
//                previousPage: previousPage.flatMap { $0 },
//                nextPage: nextPage.flatMap { $0 },
//                items: items.compactMap { $0 as? V }
//            )
//        }
//
//        func map<V>(to value: (T) -> V) -> LoadablePaging<V> {
//            .init(
//                id: id,
//                previousPage: previousPage.flatMap { $0 },
//                nextPage: nextPage.flatMap { $0 },
//                items: items.compactMap(value)
//            )
//        }
//    }
//
