//
//  Playlist.swift
//  
//
//  Created by ErrorErrorError on 5/29/23.
//  
//

import Foundation

public struct Playlist: Sendable, Identifiable, Equatable {
    public let id: String
    public let title: String?
    public let posterImage: URL?
    public let bannerImage: URL?
//    public let url: URL
//    public let status: Status
    public let type: PlaylistType

    public init(
        id: ID,
        title: String? = nil,
        posterImage: URL? = nil,
        bannerImage: URL? = nil,
        type: PlaylistType
    ) {
        self.id = id
        self.title = title
        self.posterImage = posterImage
        self.bannerImage = bannerImage
        self.type = type
    }

    public enum PlaylistType: Int, Sendable, Equatable {
        case video
        case image
        case text
    }
}

extension Playlist {
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

extension Playlist {
    public struct Item: Sendable, Equatable, Identifiable {
        public let id: String
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
            number: Double,
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

extension Playlist {
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
            type: Playlist.Preview.PreviewType
        ) {
            self.title = title
            self.description = description
            self.thumbnail = thumbnail
            self.link = link
            self.type = type
        }
    }
}

extension Playlist {
    public struct ItemsRequest {
        public let playlistId: Playlist.ID
        public let playlistItemNumber: Double?
        public let playlistItemGroup: Double?

        public init(
            playlistId: Playlist.ID,
            playlistItemNumber: Double? = nil,
            playlistItemGroup: Double? = nil
        ) {
            self.playlistId = playlistId
            self.playlistItemNumber = playlistItemNumber
            self.playlistItemGroup = playlistItemGroup
        }
    }

    public struct ItemsResponse: Equatable, Sendable {
        public let content: Group.Content
        public let allGroups: [Group]

        public init(
            content: Playlist.Group.Content,
            allGroups: [Playlist.Group]
        ) {
            self.content = content
            self.allGroups = allGroups
        }
    }

    public struct Group: Sendable, Hashable, Identifiable {
        public let id: Double
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
            public let previousGroupId: Group.ID?
            public let nextGroupId: Group.ID?
            public let items: [Item]

            public init(
                groupId: Group.ID,
                previousGroupId: Group.ID? = nil,
                nextGroupId: Group.ID? = nil,
                items: [Item] = []
            ) {
                self.groupId = groupId
                self.previousGroupId = previousGroupId
                self.nextGroupId = nextGroupId
                self.items = items
            }
        }
    }
}
