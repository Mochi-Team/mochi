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
    // FIXME: Improve Key-Value access
    // This might be a performance bottleneck, optimize in the future
    subscript(key: String) -> Any? {
        let mirror = Mirror(reflecting: self)
        for (someKey, someValue) in mirror.children where someKey == key {
            if let value = someValue as? any OpaqueTagged {
                return value.rawValue
            } else {
                return someValue
            }
        }
        return nil
    }
}

private protocol OpaqueTagged {
    associatedtype RawValue
    var rawValue: RawValue { get }
}

extension Tagged: OpaqueTagged {}

extension SearchQuery: KVAccess {}
extension SearchQuery.Filter: KVAccess {}
extension Playlist.ItemsRequest: KVAccess {}
extension Playlist.EpisodeSourcesRequest: KVAccess {}
extension Playlist.EpisodeServerRequest: KVAccess {}

extension Paging {
    func into<V>(_: V.Type = V.self) -> Paging<V> {
        .init(
            items: items.compactMap { $0 as? V },
            currentPage: currentPage,
            nextPage: nextPage
        )
    }
}
