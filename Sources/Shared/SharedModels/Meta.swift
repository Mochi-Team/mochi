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

public struct DiscoverListing: Sendable, Hashable, Identifiable, Codable {
    public let id: Tagged<Self, String>
    public let title: String
    public let type: ListingType
    public let orientation: OrientationType
    public var paging: Paging<Playlist>

    public enum ListingType: Int, Sendable, Hashable, Codable {
        case `default`
        case rank
        case featured
    }

    public enum OrientationType: Int, Sendable, Hashable, Codable {
        case portrait
        case landscape
    }

    public init(
        id: Self.ID,
        title: String,
        type: ListingType = .default,
        orientation: OrientationType = .portrait,
        paging: Paging<Playlist>
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.orientation = orientation
        self.paging = paging
    }
}

extension DiscoverListing {
    public var items: [Playlist] { paging.items }
}

public extension DiscoverListing {
    struct Request: Sendable, Codable {
        public let listingID: DiscoverListing.ID
        public let page: PagingID

        public init(
            listingID: DiscoverListing.ID,
            page: PagingID
        ) {
            self.listingID = listingID
            self.page = page
        }
    }
}

// MARK: - SearchFilter

public struct SearchFilter: Identifiable, Equatable, Sendable, Codable {
    public let id: Tagged<Self, String>
    public let displayName: String
    public let multiselect: Bool
    public let required: Bool
    public let options: [Option]

    public init(
        id: ID,
        displayName: String,
        multiselect: Bool,
        required: Bool,
        options: [Option]
    ) {
        self.id = id
        self.displayName = displayName
        self.multiselect = multiselect
        self.required = required
        self.options = options
    }

    public struct Option: Identifiable, Equatable, Sendable, Codable {
        public let id: Tagged<Self, String>
        public let displayName: String

        public init(
            id: Self.ID,
            displayName: String
        ) {
            self.id = id
            self.displayName = displayName
        }
    }
}

// MARK: - SearchQuery

public struct SearchQuery: Equatable, Sendable, Codable {
    public var query: String
    public var page: PagingID?
    public var filters: [Filter]

    public init(
        query: String,
        page: PagingID? = nil,
        filters: [Self.Filter] = []
    ) {
        self.query = query
        self.page = page
        self.filters = filters
    }

    public struct Filter: Identifiable, Equatable, Sendable, Codable {
        public let id: SearchFilter.ID
        public let optionIDs: [SearchFilter.Option.ID]

        public init(
            id: ID,
            optionId: [SearchFilter.Option.ID] = []
        ) {
            self.id = id
            self.optionIDs = optionId
        }
    }
}
