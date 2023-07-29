//
//  Playlist.swift
//
//
//  Created by ErrorErrorError on 5/29/23.
//
//

import Foundation
import Tagged

// MARK: - Playlist

public struct Playlist: Sendable, Identifiable, Hashable {
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

    public enum PlaylistType: Int, Sendable, Hashable {
        case video
        case image
        case text
    }

    public enum Status: Int, Sendable, Hashable {
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
    struct Details: Sendable, Equatable {
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

        public struct Preview: Sendable, Equatable {
            public let title: String?
            public let description: String?
            public let thumbnail: URL?
            public let link: URL
            public let type: PreviewType

            public enum PreviewType: Int, Sendable, Equatable {
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
    struct Item: Sendable, Equatable, Identifiable {
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
    struct ItemsRequest {
        public let playlistId: Playlist.ID
        public let groupId: Playlist.Group.ID?
        public let pageId: PagingID?
        public let itemId: Playlist.Item.ID?

        public init(
            playlistId: Playlist.ID,
            groupId: Playlist.Group.ID?,
            pageId: PagingID?,
            itemId: Playlist.Item.ID?
        ) {
            self.playlistId = playlistId
            self.groupId = groupId
            self.pageId = pageId
            self.itemId = itemId
        }
    }

    struct ItemsResponse: Equatable, Sendable {
        public let contents: [Group.Content]
        public let allGroups: [Group]

        public init(
            contents: [Group.Content],
            allGroups: [Group]
        ) {
            self.contents = contents
            self.allGroups = allGroups
        }
    }

    struct Group: Sendable, Hashable, Identifiable {
        public let id: Tagged<Self, Double>
        public let displayTitle: String?

        public init(
            id: Self.ID,
            displayTitle: String? = nil
        ) {
            self.id = id
            self.displayTitle = displayTitle
        }

        public struct Content: Equatable, Sendable {
            public let groupId: Group.ID
            public let pagings: [Paging<Item>]
            public let allPages: [Page]

            public init(
                groupId: Playlist.Group.ID,
                pagings: [Paging<Playlist.Item>],
                allPagesInfo: [Page]
            ) {
                self.groupId = groupId
                self.pagings = pagings
                self.allPages = allPagesInfo
            }

            public struct Page: Hashable, Sendable, Identifiable {
                public let id: PagingID
                public let displayName: String

                public init(
                    id: Paging<Playlist.Item>.ID,
                    displayName: String
                ) {
                    self.id = id
                    self.displayName = displayName
                }
            }
        }
    }
}

// MARK: - PlaylistInfo

@dynamicMemberLookup
public struct PlaylistInfo: Equatable, Sendable {
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
