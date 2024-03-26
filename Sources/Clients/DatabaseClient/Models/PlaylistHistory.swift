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
public struct PlaylistHistory: Equatable, Sendable, Hashable {
  @Attribute public var playlistID = ""
  @Attribute public var playlistName = String?.none

  @Attribute public var dateWatched = Date.now
  @Attribute public var playlist = Date.now
  @Attribute public var moduleId = ""
  @Attribute public var repoId = ""
  @Attribute public var timestamp = 0.0

  @Attribute public var thumbnail = URL?.none
  @Attribute public var epId = ""
  @Attribute public var epName = String?.none

  @Attribute public var pageId = ""
  @Attribute public var groupId = ""
  @Attribute public var variantId = ""

  public init(
    playlistID: String,
    timestamp: Double = 0.0,
    epId: String,
    playlistName: String?,
    moduleId: String,
    repoId: String,
    thumbnail: URL? = nil,
    epName: String?,
    pageId: String,
    groupId: String,
    variantId: String
  ) {
    self.playlistID = playlistID
    self.timestamp = timestamp
    self.epId = epId
    self.playlistName = playlistName
    self.thumbnail = thumbnail
    self.dateWatched = Date.now
    self.moduleId = moduleId
    self.repoId = repoId
    self.epName = epName
    self.pageId = pageId
    self.groupId = groupId
    self.variantId = variantId
  }
}
