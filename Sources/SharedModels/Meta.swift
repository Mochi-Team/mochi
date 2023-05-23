//
//  Media.swift
//
//
//  Created by ErrorErrorError on 4/5/23.
//
//

import Foundation
import Tagged

public struct DiscoverListing: Sendable, Equatable {
    public let title: String
    public let type: ListingType
    public var paging: Paging<Media>

    public var items: [Media] {
        paging.items
    }

    public enum ListingType: Int, Sendable, Equatable {
        case `default`
        case rank
        case featured
    }

    public init(
        title: String,
        type: ListingType,
        paging: Paging<Media>
    ) {
        self.title = title
        self.type = type
        self.paging = paging
    }
}

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

public struct SearchQuery: Equatable, Sendable {
    public init(
        query: String,
        page: String? = nil,
        filters: [SearchQuery.Filter] = []
    ) {
        self.query = query
        self.page = page
        self.filters = filters
    }

    public var query: String
    public var page: String?
    public var filters: [Filter]

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

public struct Media: Sendable, Identifiable, Equatable {
    public let id: Tagged<Self, String>
    public let title: String?
    public let posterImage: URL?
    public let bannerImage: URL?
//    public let url: URL
//    public let status: Status
    public let meta: Meta

    public init(
        id: ID,
        title: String? = nil,
        posterImage: URL? = nil,
        bannerImage: URL? = nil,
        meta: Meta
    ) {
        self.id = id
        self.title = title
        self.posterImage = posterImage
        self.bannerImage = bannerImage
        self.meta = meta
    }

    public enum Meta: Int, Sendable, Equatable {
        case video
        case image
        case text
    }
}

extension Media {
    public struct Details: Sendable, Equatable {
        public let contentDescription: String?
        public let alternativeTitles: [String]
        public let alternativePosters: [URL]
        public let alternativeBanners: [URL]
        public let genres: [String]
        public let yearReleased: Int?
        public let ratings: Int?
        public let previews: [Preview]

        public init(
            contentDescription: String? = nil,
            alternativeTitles: [String] = [],
            alternativePosters: [URL] = [],
            alternativeBanners: [URL] = [],
            genres: [String] = [],
            yearReleased: Int? = nil,
            ratings: Int? = nil,
            previews: [Preview] = []
        ) {
            self.contentDescription = contentDescription
            self.alternativeTitles = alternativeTitles
            self.alternativePosters = alternativePosters
            self.alternativeBanners = alternativeBanners
            self.genres = genres
            self.yearReleased = yearReleased
            self.ratings = ratings
            self.previews = previews
        }
    }
}

extension Media {
    public struct Content: Sendable, Equatable {
        public let title: String?
        public let description: String?
        public let thumbnail: URL?
        public let section: String?
        public let group: Double?
        public let number: Double
        public let timestamp: String?
        public let tags: [String]
        public let link: String

        public init(
            title: String? = nil,
            description: String? = nil,
            thumbnail: URL? = nil,
            section: String? = nil,
            group: Double? = nil,
            number: Double,
            timestamp: String? = nil,
            tags: [String] = [],
            link: String
        ) {
            self.title = title
            self.description = description
            self.thumbnail = thumbnail
            self.section = section
            self.group = group
            self.number = number
            self.timestamp = timestamp
            self.tags = tags
            self.link = link
        }
    }
}

extension Media {
    public struct Preview: Sendable, Equatable {
        public let title: String?
        public let description: String?
        public let thumbnail: URL
        public let link: URL
        public let type: PreviewType

        public enum PreviewType: Sendable, Equatable {
            case video
            case image
        }

        public init(
            title: String? = nil,
            description: String? = nil,
            thumbnail: URL,
            link: URL,
            type: Media.Preview.PreviewType
        ) {
            self.title = title
            self.description = description
            self.thumbnail = thumbnail
            self.link = link
            self.type = type
        }
    }
}

//extension Media {
//    public struct Link: Equatable, Sendable {
//        public let name: String?
//        public let image: URL?
//        public let url: URL
//
//        public enum LinkType: Equatable, Sendable {
//            case video
//            case image
//            case text
//        }
//    }
//}
