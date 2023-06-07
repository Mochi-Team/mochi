//
//  Playlist+Video.swift
//  
//
//  Created by ErrorErrorError on 4/18/23.
//  
//

import Foundation
import Tagged

extension Playlist {
    public struct EpisodeSourcesRequest: Sendable, Equatable {
        public let playlistId: Playlist.ID
        public let episodeId: Playlist.Item.ID

        public init(
            playlistId: Playlist.ID,
            episodeId: Playlist.Item.ID
        ) {
            self.playlistId = playlistId
            self.episodeId = episodeId
        }
    }

    public struct EpisodeServerRequest: Sendable, Equatable {
        public let playlistId: Playlist.ID
        public let episodeId: Playlist.Item.ID
        public let sourceId: EpisodeSource.ID
        public let serverId: EpisodeServer.ID

        public init(
            playlistId: Playlist.ID,
            episodeId: Playlist.Item.ID,
            sourceId: Playlist.EpisodeSource.ID,
            serverId: Playlist.EpisodeServer.ID
        ) {
            self.playlistId = playlistId
            self.episodeId = episodeId
            self.sourceId = sourceId
            self.serverId = serverId
        }
    }

    public struct EpisodeSource: Sendable, Equatable, Identifiable {
        public let id: Tagged<Self, String>
        public let displayName: String
        public let description: String?
        public let servers: [EpisodeServer]

        public init(
            id: Self.ID,
            displayName: String,
            description: String? = nil,
            servers: [Playlist.EpisodeServer] = []
        ) {
            self.id = id
            self.displayName = displayName
            self.description = description
            self.servers = servers
        }
    }

    public struct EpisodeServer: Sendable, Equatable, Identifiable {
        public let id: Tagged<Self, String>
        public let displayName: String
        public let description: String?

        public init(
            id: Self.ID,
            displayName: String,
            description: String? = nil
        ) {
            self.id = id
            self.displayName = displayName
            self.description = description
        }

        public struct Link: Sendable, Equatable {
            public let url: URL
            public let quality: Quality

            public init(
                url: URL,
                quality: Playlist.EpisodeServer.Quality
            ) {
                self.url = url
                self.quality = quality
            }
        }

        public enum Quality: RawRepresentable, Sendable, Equatable {
            case auto
            case q1080
            case q720
            case q480
            case q360
            case custom(Int)

            public init?(rawValue: Int) {
                if rawValue == Self.auto.rawValue {
                    self = .auto
                } else if rawValue == Self.q1080.rawValue {
                    self = .q1080
                } else if rawValue == Self.q720.rawValue {
                    self = .q720
                } else if rawValue == Self.q480.rawValue {
                    self = .q480
                } else if rawValue == Self.q360.rawValue {
                    self = .q360
                } else if rawValue > 0 {
                    self = .custom(rawValue)
                } else {
                    return nil
                }
            }

            public var rawValue: Int {
                switch self {
                case .auto:
                    return Int.max
                case .q1080:
                    return 1_080
                case .q720:
                    return 720
                case .q480:
                    return 480
                case .q360:
                    return 360
                case let .custom(res):
                    return res
                }
            }
        }

        public struct Subtitle: Sendable, Equatable {
            public let url: URL
            public let language: String

            public init(
                url: URL,
                language: String
            ) {
                self.language = language
                self.url = url
            }
        }

        public enum Format: Int32, Equatable, Sendable {
            case hls
            case dash
        }
    }

    public struct EpisodeServerResponse: Equatable, Sendable {
        public let links: [Playlist.EpisodeServer.Link]
        public let subtitles: [Playlist.EpisodeServer.Subtitle]
        public let formatType: Playlist.EpisodeServer.Format

        public init(
            links: [Playlist.EpisodeServer.Link] = [],
            subtitles: [Playlist.EpisodeServer.Subtitle] = [],
            formatType: Playlist.EpisodeServer.Format = .hls
        ) {
            self.links = links
            self.subtitles = subtitles
            self.formatType = formatType
        }
    }
}
