//
//  File.swift
//  
//
//  Created by ErrorErrorError on 4/18/23.
//  
//

import Foundation

public struct Listing<T> {
    public init(
        title: String,
        paging: Paging<T>
    ) {
        self.title = title
        self.paging = paging
    }

    public let title: String
    public let paging: Paging<T>
}

extension Listing: Equatable where T: Equatable {}
extension Listing: Sendable where T: Sendable {}
