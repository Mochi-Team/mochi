//
//  File.swift
//  
//
//  Created by ErrorErrorError on 4/18/23.
//  
//

import Foundation

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

extension Paging: Equatable where T: Equatable {}
extension Paging: Sendable where T: Sendable {}
