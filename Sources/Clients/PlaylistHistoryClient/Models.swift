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

  public struct RMP: Equatable, Sendable {
    public let repoId: String
    public let moduleId: String
    public let playlistId: String

    public init(repoId: String, moduleId: String, playlistId: String) {
      self.repoId = repoId
      self.moduleId = moduleId
      self.playlistId = playlistId
    }
  }

  public struct EpIdPayload: Equatable, Sendable {
    public let rmp: RMP
    public let episode: Playlist.Item
    public let playlistName: String?
    public let pageId: String
    public let groupId: String
    public let variantId: String

    public init(rmp: RMP, episode: Playlist.Item, playlistName: String?, pageId: String, groupId: String, variantId: String) {
      self.rmp = rmp
      self.episode = episode
      self.playlistName = playlistName
      self.pageId = pageId
      self.groupId = groupId
      self.variantId = variantId
    }
  }
}
