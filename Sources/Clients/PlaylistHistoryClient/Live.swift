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
      if var playlist = try? await databaseClient.fetch(.all.where(\PlaylistHistory.playlistID == payload.playlistID)).first {
        playlist.epId = payload.episode.id.rawValue
        playlist.lastModuleId = payload.moduleId.rawValue
        playlist.dateWatched = Date.now
        playlist.epName = payload.episode.title
        playlist.lastRepoId = payload.repoId.absoluteString
        playlist.groupId = payload.groupId
        playlist.variantId = payload.variantId
        playlist.pageId = payload.pageId
        playlist.thumbnail = payload.episode.thumbnail
        try await databaseClient.update(playlist)
      } else {
        try await databaseClient.insert(PlaylistHistory(playlistID: payload.playlistID, epId: payload.episode.id.rawValue, playlistName: payload.playlistName, lastModuleId: payload.moduleId.rawValue, lastRepoId: payload.repoId.absoluteString, thumbnail: payload.episode.thumbnail, epName: payload.episode.title, pageId: payload.pageId, groupId: payload.groupId, variantId: payload.variantId))
      }
    },
    fetch: { playlistID in
      guard let playlistHistory = try? await databaseClient.fetch(.all.where(\PlaylistHistory.playlistID == playlistID)).first else {
        throw PlaylistHistoryClient.Error.failedToFindPlaylisthistory
      }
      return playlistHistory
    },
    observeModule: { moduleId in
      databaseClient.observe(.all.where(\PlaylistHistory.lastModuleId == moduleId))
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
