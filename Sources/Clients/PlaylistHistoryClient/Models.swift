//
//  Models.swift
//
//
//  Created by DeNeRr on 29.01.2024.
//

import Foundation
import SharedModels

extension PlaylistHistoryClient {
  public enum Error: Swift.Error, Equatable, Sendable {
    case failedToFindPlaylisthistory
  }
  
  public struct EpIdPayload: Equatable, Sendable {
    public let playlistID: String
    public let episode: Playlist.Item
    public let playlistName: String?
    public let moduleId: Module.ID
    public let repoId: Repo.ID
    public let pageId: String
    public let groupId: String
    public let variantId: String
    
    public init(playlistID: String, episode: Playlist.Item, playlistName: String?, moduleId: Module.ID, repoId: Repo.ID, pageId: String, groupId: String, variantId: String) {
      self.playlistID = playlistID
      self.episode = episode
      self.playlistName = playlistName
      self.moduleId = moduleId
      self.repoId = repoId
      self.pageId = pageId
      self.groupId = groupId
      self.variantId = variantId
    }
  }
}
