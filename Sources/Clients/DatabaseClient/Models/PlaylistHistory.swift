//
//  PlaylistHistory.swift
//
//
//  Created by DeNeRr on 27.01.2024.
//

import CoreDB
import Foundation

// MARK: PlaylistHistory

@Entity
public struct PlaylistHistory: Equatable, Sendable {
  @Attribute public var playlistID = String?.none
  @Attribute public var lastWatchedEpisode = 1.0
  @Attribute public var timestamp: Double = 0.0

  public init(
    playlistID: String?,
    timestamp: Double = 0.0,
    lastWatchedEpisode: Double
  ) {
    self.playlistID = playlistID
    self.timestamp = timestamp
    self.lastWatchedEpisode = lastWatchedEpisode
  }
}
