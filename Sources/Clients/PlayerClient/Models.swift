//
//  Models.swift
//
//
//  Created by ErrorErrorError on 5/26/23.
//
//

import Foundation

// MARK: - PlayerClient.Status

public extension PlayerClient {
    // TODO: Add metadata in the status
    enum Status: Hashable, Sendable {
        case idle
        case loading
        case playback(Playback)
        case error

        public struct Playback: Hashable, Sendable {
            public let progress: Double
            public let status: State

            public enum State: Hashable, Sendable {
                case playing
                case paused
                case buffering
            }
        }
    }
}

public extension PlayerClient {
    struct VideoCompositionItem {
        let link: URL
        let headers: [String: String]
        let subtitles: [Subtitle]
        let metadata: SourceMetadata

        public init(
            link: URL,
            headers: [String: String] = [:],
            subtitles: [Subtitle] = [],
            metadata: SourceMetadata
        ) {
            self.link = link
            self.headers = headers
            self.subtitles = subtitles
            self.metadata = metadata
        }

        public struct Subtitle {
            let name: String
            let `default`: Bool
            let autoselect: Bool
            let forced: Bool
            let link: URL

            public init(
                name: String,
                default: Bool,
                autoselect: Bool,
                forced: Bool = false,
                link: URL
            ) {
                self.name = name
                self.default = `default`
                self.autoselect = autoselect
                self.forced = forced
                self.link = link
            }
        }
    }

    struct SourceMetadata {
        let title: String?
        let subtitle: String?
        let artworkImage: URL?
        let author: String?

        public init(
            title: String? = nil,
            subtitle: String? = nil,
            artworkImage: URL? = nil,
            author: String? = nil
        ) {
            self.title = title
            self.subtitle = subtitle
            self.artworkImage = artworkImage
            self.author = author
        }
    }
}
