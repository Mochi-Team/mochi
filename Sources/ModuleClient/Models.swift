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

// MARK: - KVAccess

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

// MARK: - OpaqueTagged

private protocol OpaqueTagged {
    associatedtype RawValue
    var rawValue: RawValue { get }
}

extension OpaqueTagged where Self: RawRepresentable {}

// MARK: - Tagged + OpaqueTagged

extension Tagged: OpaqueTagged {}

// MARK: - PagingID + OpaqueTagged

extension PagingID: OpaqueTagged {
    var rawValue: RawValue { self[dynamicMember: \.rawValue] }
}

// MARK: - SearchQuery + KVAccess

extension SearchQuery: KVAccess {}

// MARK: - SearchQuery.Filter + KVAccess

extension SearchQuery.Filter: KVAccess {}

// MARK: - Playlist.ItemsRequest + KVAccess

extension Playlist.ItemsRequest: KVAccess {}

// MARK: - Playlist.EpisodeSourcesRequest + KVAccess

extension Playlist.EpisodeSourcesRequest: KVAccess {}

// MARK: - Playlist.EpisodeServerRequest + KVAccess

extension Playlist.EpisodeServerRequest: KVAccess {}
