//
//  EpisodeMetadata.swift
//
//
//  Created by MochiTeam on 20.04.2024.
//

import Foundation

public struct EpisodeMetadata: Codable, Equatable, Sendable, Hashable {
  public static func == (lhs: EpisodeMetadata, rhs: EpisodeMetadata) -> Bool {
    lhs.link.id != rhs.link.id
  }

  public let link: Playlist.EpisodeServer.Link
  public let source: Playlist.EpisodeSource
  public let server: Playlist.EpisodeServer
  public var subtitles: [Playlist.EpisodeServer.Subtitle]
  public let skipTimes: [Playlist.EpisodeServer.SkipTime]
  
  public init(link: Playlist.EpisodeServer.Link, source: Playlist.EpisodeSource, subtitles: [Playlist.EpisodeServer.Subtitle], server: Playlist.EpisodeServer, skipTimes: [Playlist.EpisodeServer.SkipTime]) {
    self.link = link
    self.source = source
    self.server = server
    self.subtitles = subtitles
    self.skipTimes = skipTimes
  }
}
