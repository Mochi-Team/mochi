//
//  Meta.swift
//
//
//  Created by ErrorErrorError on 4/5/23.
//
//

import Foundation
import Tagged

// MARK: - DiscoverListing

public struct DiscoverListing: Sendable, Hashable {
    public let title: String
    public let type: ListingType
    public var paging: Paging<Playlist>

    public var items: [Playlist] {
        paging.items
    }

    public enum ListingType: Int, Sendable, Hashable {
        case `default`
        case rank
        case featured
    }

    public init(
        title: String,
        type: ListingType,
        paging: Paging<Playlist>
    ) {
        self.title = title
        self.type = type
        self.paging = paging
    }
}

// MARK: - SearchFilter

public struct SearchFilter: Identifiable, Equatable, Sendable {
    public let id: Tagged<Self, String>
    public let displayName: String
    public let multiSelect: Bool
    public let required: Bool
    public let options: [Option]

    public init(
        id: ID,
        displayName: String,
        multiSelect: Bool,
        required: Bool,
        options: [Option]
    ) {
        self.id = id
        self.displayName = displayName
        self.multiSelect = multiSelect
        self.required = required
        self.options = options
    }

    public struct Option: Identifiable, Equatable, Sendable {
        public let id: Tagged<Self, String>
        public let displayName: String

        public init(
            id: Option.ID,
            displayName: String
        ) {
            self.id = id
            self.displayName = displayName
        }
    }
}

// MARK: - SearchQuery

public struct SearchQuery: Equatable, Sendable {
    public var query: String
    public var page: PagingID?
    public var filters: [Filter]

    public init(
        query: String,
        page: PagingID? = nil,
        filters: [SearchQuery.Filter] = []
    ) {
        self.query = query
        self.page = page
        self.filters = filters
    }

    public struct Filter: Identifiable, Equatable, Sendable {
        public let id: SearchFilter.ID
        public let optionId: SearchFilter.Option.ID

        public init(
            id: ID,
            optionId: SearchFilter.Option.ID
        ) {
            self.id = id
            self.optionId = optionId
        }
    }
}
