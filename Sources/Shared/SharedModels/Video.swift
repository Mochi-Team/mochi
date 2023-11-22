//
//  Video.swift
//
//
//  Created by ErrorErrorError on 4/18/23.
//
//

import Foundation
import Tagged

public extension Playlist {
    struct EpisodeSourcesRequest: Sendable, Equatable, Encodable {
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

    struct EpisodeServerRequest: Sendable, Equatable, Encodable {
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

    struct EpisodeSource: Sendable, Equatable, Identifiable, Decodable {
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

    struct EpisodeServer: Sendable, Equatable, Identifiable, Decodable {
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

        public struct Link: Sendable, Equatable, Identifiable, Decodable {
            public var id: Tagged<Self, URL> { .init(url) }
            public let url: URL
            public let quality: Quality
            public let format: Format

            public init(
                url: URL,
                quality: Quality,
                format: Format
            ) {
                self.url = url
                self.quality = quality
                self.format = format
            }

            public enum Quality: Int, Sendable, Equatable, CustomStringConvertible, Decodable {
                case auto
                case q360
                case q480
                case q720
                case q1080

                public var description: String {
                    switch self {
                    case .auto:
                        "Auto"
                    case .q1080:
                        "1080p"
                    case .q720:
                        "720p"
                    case .q480:
                        "480p"
                    case .q360:
                        "360p"
                    }
                }
            }

            public enum Format: Int, Equatable, Sendable, Decodable {
                case hls
                case dash
            }
        }

        public struct Subtitle: Sendable, Equatable, Identifiable, Decodable {
            public var id: Tagged<Self, URL> { .init(url) }
            public let url: URL
            public let name: String
            public let format: Format
            public let `default`: Bool
            public let autoselect: Bool

            public init(
                url: URL,
                name: String,
                format: Format,
                default: Bool = false,
                autoselect: Bool = false
            ) {
                self.name = name
                self.url = url
                self.format = format
                self.default = `default`
                self.autoselect = autoselect
            }

            public enum Format: Int32, Sendable, Equatable, Decodable {
                case vtt
                case ass
                case srt
            }
        }

        public struct SkipTime: Hashable, Sendable, Decodable {
            public let startTime: Double
            public let endTime: Double
            public let type: SkipType

            public init(
                startTime: Double,
                endTime: Double,
                type: Playlist.EpisodeServer.SkipTime.SkipType
            ) {
                self.startTime = startTime
                self.endTime = endTime
                self.type = type
            }

            public enum SkipType: Int32, Equatable, Sendable, CustomStringConvertible, Decodable {
                case opening
                case ending
                case recap

                public var description: String {
                    switch self {
                    case .opening:
                        "Skip Opening"
                    case .ending:
                        "Skip Ending"
                    case .recap:
                        "Skip Recap"
                    }
                }
            }
        }
    }

    struct EpisodeServerResponse: Equatable, Sendable, Decodable {
        public let links: [Playlist.EpisodeServer.Link]
        public let subtitles: [Playlist.EpisodeServer.Subtitle]
        public let headers: [String: String]
        public let skipTimes: [Playlist.EpisodeServer.SkipTime]

        public init(
            links: [Playlist.EpisodeServer.Link] = [],
            subtitles: [Playlist.EpisodeServer.Subtitle] = [],
            headers: [String: String],
            skipTimes: [Playlist.EpisodeServer.SkipTime]
        ) {
            self.links = links
            self.subtitles = subtitles
            self.headers = headers
            self.skipTimes = skipTimes
        }
    }
}
