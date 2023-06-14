//
//  File.swift
//
//
//  Created by ErrorErrorError on 4/18/23.
//
//

import Foundation

// MARK: - Paging

public struct Paging<T> {
    public init(
        items: [T] = [],
        currentPage: String,
        nextPage: String? = nil
    ) {
        self.items = items
        self.currentPage = currentPage
        self.nextPage = nextPage
    }

    public let items: [T]
    public let currentPage: String
    public let nextPage: String?
}

// MARK: Equatable

extension Paging: Equatable where T: Equatable {}

// MARK: Sendable

extension Paging: Sendable where T: Sendable {}
