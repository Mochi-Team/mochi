//
//  Live.swift
//
//
//  Created by DeNeRr on 28.01.2024.
//

import DatabaseClient
import Dependencies
import Foundation
import Semaphore

// MARK: - PlaylistHistoryClient + DependencyKey

extension PlaylistHistoryClient: DependencyKey {
  @Dependency(\.databaseClient) private static var databaseClient

  public static let liveValue = Self(
    updateLastWatchedEpisode: { playlistID, epNumber in
      if var playlist = try? await databaseClient.fetch(.all.where(\PlaylistHistory.playlistID == playlistID)).first {
        playlist.lastWatchedEpisode = epNumber ?? 1
        _ = try await databaseClient.update(playlist)
      } else {
        _ = try await databaseClient.insert(PlaylistHistory(playlistID: playlistID, lastWatchedEpisode: epNumber ?? 1))
      }
    },
    fetch: { playlistID in
      guard let playlistHistory = try? await databaseClient.fetch(.all.where(\PlaylistHistory.playlistID == playlistID)).first else {
        throw PlaylistHistoryClient.Error.failedToFindPlaylisthistory
      }
      return playlistHistory
    },
    updateTimestamp: { playlistID, timestamp in
      if var playlist = try? await databaseClient.fetch(.all.where(\PlaylistHistory.playlistID == playlistID)).first {
        playlist.timestamp = timestamp
        _ = try await databaseClient.update(playlist)
      }
    },
    observe: { playlistID in
      databaseClient.observe(.all.where(\PlaylistHistory.playlistID == playlistID))
    }
  )
}
