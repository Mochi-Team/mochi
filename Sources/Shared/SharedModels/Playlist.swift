//
//  Playlist.swift
//
//
//  Created by ErrorErrorError on 5/29/23.
//
//

import Foundation
import Tagged
import JSValueCoder

// MARK: - Playlist

public struct Playlist: Sendable, Identifiable, Hashable, Codable {
    public let id: Tagged<Self, String>
    public let title: String?
    public let posterImage: URL?
    public let bannerImage: URL?
    public let url: URL
    public let status: Status
    public let type: PlaylistType

    public init(
        id: ID,
        title: String?,
        posterImage: URL?,
        bannerImage: URL?,
        url: URL,
        status: Status,
        type: PlaylistType
    ) {
        self.id = id
        self.title = title
        self.posterImage = posterImage
        self.bannerImage = bannerImage
        self.url = url
        self.status = status
        self.type = type
    }

    public enum PlaylistType: Int, Sendable, Hashable, Codable {
        case video
        case image
        case text
    }

    public enum Status: Int, Sendable, Hashable, Codable {
        case unknown
        case upcoming
        case ongoing
        case completed
        case paused
        case cancelled
    }
}

// MARK: Playlist.Details

public extension Playlist {
    struct Details: Sendable, Equatable, Codable {
        public let synopsis: String?
        public let altTitles: [String]
        public let altPosters: [URL]
        public let altBanners: [URL]
        public let genres: [String]
        public let yearReleased: Int?
        public let ratings: Int?
        public let previews: [Preview]

        public init(
            synopsis: String? = nil,
            altTitles: [String] = [],
            altPosters: [URL] = [],
            altBanners: [URL] = [],
            genres: [String] = [],
            yearReleased: Int? = nil,
            ratings: Int? = nil,
            previews: [Preview] = []
        ) {
            self.synopsis = synopsis
            self.altTitles = altTitles
            self.altPosters = altPosters
            self.altBanners = altBanners
            self.genres = genres
            self.yearReleased = yearReleased
            self.ratings = ratings
            self.previews = previews
        }

        public struct Preview: Sendable, Equatable, Codable {
            public let title: String?
            public let description: String?
            public let thumbnail: URL?
            public let link: URL
            public let type: PreviewType

            public enum PreviewType: Int, Sendable, Equatable, Codable {
                case video
                case image
            }

            public init(
                title: String? = nil,
                description: String? = nil,
                thumbnail: URL? = nil,
                link: URL,
                type: PreviewType
            ) {
                self.title = title
                self.description = description
                self.thumbnail = thumbnail
                self.link = link
                self.type = type
            }
        }
    }
}

// MARK: Playlist.Item

public extension Playlist {
    struct Item: Sendable, Equatable, Identifiable, Codable {
        public let id: Tagged<Self, String>
        public let title: String?
        public let description: String?
        public let thumbnail: URL?
        public let number: Double
        public let timestamp: String?
        public let tags: [String]

        public init(
            id: Self.ID,
            title: String? = nil,
            description: String? = nil,
            thumbnail: URL? = nil,
            number: Float64,
            timestamp: String? = nil,
            tags: [String] = []
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.thumbnail = thumbnail
            self.number = number
            self.timestamp = timestamp
            self.tags = tags
        }
    }
}

public extension Playlist {

    // TODO: Write a codable that handles all the boilerplate when converting to JSValue

    enum ItemsRequestOptions: Sendable, Equatable, Encodable {
        case group(Playlist.Group.ID)
        case variant(Playlist.Group.ID, Playlist.Group.Variant.ID)
        case page(Playlist.Group.ID, Playlist.Group.Variant.ID, PagingID)

        var type: String {
            switch self {
            case .group:
                "group"
            case .variant:
                "variant"
            case .page:
                "page"
            }
        }

        enum GroupCodingKeys: JSValueEnumCodingKey {
            case type
            case groupID
        }

        enum VariantCodingKeys: JSValueEnumCodingKey {
            case type
            case groupID
            case variantID
        }

        enum PageCodingKeys: JSValueEnumCodingKey {
            case type
            case groupID
            case variantID
            case pageID
        }

        public func encode(to encoder: Encoder) throws {
            switch self {
            case let .group(groupID):
                var container = encoder.container(keyedBy: GroupCodingKeys.self)
                try container.encode(type, forKey: .type)
                try container.encode(groupID, forKey: .groupID)
            case let .variant(groupID, variantID):
                var container = encoder.container(keyedBy: VariantCodingKeys.self)
                try container.encode(type, forKey: .type)
                try container.encode(groupID, forKey: .groupID)
                try container.encode(variantID, forKey: .variantID)
            case let .page(groupID, variantID, pageID):
                var container = encoder.container(keyedBy: PageCodingKeys.self)
                try container.encode(type, forKey: .type)
                try container.encode(groupID, forKey: .groupID)
                try container.encode(variantID, forKey: .variantID)
                try container.encode(pageID, forKey: .pageID)
            }
        }
    }

    enum ItemsResponse: Equatable, Sendable, Decodable {
        case groups([Playlist.Group])
        case variants([Playlist.Group.Variant])
        case pagings([Paging<Playlist.Item>])

        enum CodingKeys: CodingKey {
            case type
            case items
        }

        private enum ResponseType: String, Decodable {
            case groups
            case variants
            case pagings
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            let type = try container.decode(ResponseType.self, forKey: .type)

            switch type {
            case .groups:
                self = try .groups(container.decode([Playlist.Group].self, forKey: .items))
            case .variants:
                self = try .variants(container.decode([Playlist.Group.Variant].self, forKey: .items))
            case .pagings:
                self = try .pagings(container.decode([Paging<Playlist.Item>].self, forKey: .items))
            }
        }
    }

    struct Group: Sendable, Equatable, Identifiable, Decodable {
        public let id: Tagged<Self, String>
        public let number: Double
        public let altTitle: String?
        public let variants: Loadable<[Variant]>

        public init(
            id: Self.ID,
            number: Double,
            altTitle: String? = nil,
            variants: Loadable<[Variant]> = .pending
        ) {
            self.id = id
            self.number = number
            self.altTitle = altTitle
            self.variants = variants
        }

        public struct Variant: Equatable, Sendable, Decodable, Identifiable {
            public let id: Tagged<Self, String>
            public let title: String
            public let icon: URL?
            public let pagings: Loadable<[LoadablePaging<Item>]>

            public init(
                id: Self.ID,
                title: String,
                icon: URL? = nil,
                pagings: Loadable<[LoadablePaging<Item>]> = .pending
            ) {
                self.id = id
                self.title = title
                self.icon = icon
                self.pagings = pagings
            }
        }
    }
}

// MARK: - PlaylistInfo

@dynamicMemberLookup
public struct PlaylistInfo: Equatable, Sendable, Codable {
    let playlist: Playlist
    let details: Playlist.Details

    public init(
        playlist: Playlist,
        details: Playlist.Details = .init()
    ) {
        self.playlist = playlist
        self.details = details
    }

    public subscript<Value>(dynamicMember dynamicMember: KeyPath<Playlist, Value>) -> Value {
        playlist[keyPath: dynamicMember]
    }

    public subscript<Value>(dynamicMember dynamicMember: KeyPath<Playlist.Details, Value>) -> Value {
        details[keyPath: dynamicMember]
    }
}

public extension Playlist {
    static let empty: Self = .init(
        id: "",
        title: "",
        posterImage: nil,
        bannerImage: nil,
        url: .init(string: "/").unsafelyUnwrapped,
        status: .unknown,
        type: .video
    )

    static func placeholder(_ id: Int) -> Self {
        .init(
            id: "\(id)",
            title: "Placeholder \(id)",
            posterImage: nil,
            bannerImage: nil,
            url: .init(string: "/").unsafelyUnwrapped,
            status: .unknown,
            type: .video
        )
    }
}
