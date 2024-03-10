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
    updateEpId: { payload in
      if var playlist = try? await databaseClient
        .fetch(.all.where(\PlaylistHistory.repoId == payload.rmp.repoId).where(\PlaylistHistory.moduleId == payload.rmp.moduleId).where(\PlaylistHistory.playlistID == payload.rmp.playlistId)).first {
        playlist.epId = payload.episode.id.rawValue
        playlist.dateWatched = Date.now
        playlist.epName = payload.episode.title
        playlist.groupId = payload.groupId
        playlist.variantId = payload.variantId
        playlist.pageId = payload.pageId
        playlist.thumbnail = payload.episode.thumbnail
        _ = try await databaseClient.update(playlist)
      } else {
        _ = try await databaseClient.insert(PlaylistHistory(
          playlistID: payload.rmp.playlistId,
          epId: payload.episode.id.rawValue,
          playlistName: payload.playlistName,
          moduleId: payload.rmp.moduleId,
          repoId: payload.rmp.repoId,
          thumbnail: payload.episode.thumbnail,
          epName: payload.episode.title,
          pageId: payload.pageId,
          groupId: payload.groupId,
          variantId: payload.variantId
        ))
      }
    },
    fetch: { rmp in
      guard let playlistHistory = try? await databaseClient
        .fetch(.all.where(\PlaylistHistory.repoId == rmp.repoId).where(\PlaylistHistory.moduleId == rmp.moduleId).where(\PlaylistHistory.playlistID == rmp.playlistId)).first else {
        throw PlaylistHistoryClient.Error.failedToFindPlaylisthistory
      }
      return playlistHistory
    },
    fetchForModule: { repoId, moduleId in
      let history = try? await databaseClient.fetch(.all.where(\PlaylistHistory.repoId == repoId).where(\PlaylistHistory.moduleId == moduleId))

      return history?.sorted(by: { $0.dateWatched > $1.dateWatched }) ?? []
    },
    updateTimestamp: { rmp, timestamp in
      if var playlist = try? await databaseClient
        .fetch(.all.where(\PlaylistHistory.repoId == rmp.repoId).where(\PlaylistHistory.moduleId == rmp.moduleId).where(\PlaylistHistory.playlistID == rmp.playlistId)).first {
        playlist.timestamp = timestamp
        _ = try await databaseClient.update(playlist)
      }
    },
    updateDateWatched: { rmp in
      if var playlist = try? await databaseClient
        .fetch(.all.where(\PlaylistHistory.repoId == rmp.repoId).where(\PlaylistHistory.moduleId == rmp.moduleId).where(\PlaylistHistory.playlistID == rmp.playlistId)).first {
        playlist.dateWatched = Date.now
        _ = try await databaseClient.update(playlist)
      }
    },
    observe: { rmp in
      databaseClient.observe(.all.where(\PlaylistHistory.repoId == rmp.repoId).where(\PlaylistHistory.moduleId == rmp.moduleId).where(\PlaylistHistory.playlistID == rmp.playlistId))
    },
    clearHistory: {
      for playlistHistory in try await databaseClient.fetch(.all.where(\PlaylistHistory.playlistID != nil)) {
        try await databaseClient.delete(playlistHistory)
      }
    },
    removePlaylistHistory: { rmp in
      guard let playlistHistory = try? await databaseClient
        .fetch(.all.where(\PlaylistHistory.repoId == rmp.repoId).where(\PlaylistHistory.moduleId == rmp.moduleId).where(\PlaylistHistory.playlistID == rmp.playlistId)).first else {
        throw PlaylistHistoryClient.Error.failedToFindPlaylisthistory
      }

      try await databaseClient.delete(playlistHistory)
    }
  )
}
