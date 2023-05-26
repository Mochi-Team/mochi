//
//  Models.swift
//  
//
//  Created by ErrorErrorError on 4/10/23.
//  
//

import Foundation
import SharedModels
import Tagged

protocol KVAccess {}

extension KVAccess {
    // TODO: Improve Key-Value access
    // This might be a performance bottleneck, optimize in the future
    subscript(key: String) -> Any? {
        Mirror(reflecting: self)
            .children
            .first { $0.label == key }?
            .value
    }
}

extension SearchQuery: KVAccess {}
extension SearchQuery.Filter: KVAccess {}
extension Playlist.ItemsRequest: KVAccess {}

extension Paging {
    func into<V>(_: V.Type = V.self) -> Paging<V> {
        .init(
            items: items.compactMap { $0 as? V },
            currentPage: currentPage,
            nextPage: nextPage
        )
    }
}
