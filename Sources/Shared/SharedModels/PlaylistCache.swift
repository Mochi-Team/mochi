//
//  PlaylistCache.swift
//
//
//  Created by MochiTeam on 17.04.2024.
//

import Foundation

public struct RepoModuleId: Codable, Sendable {
  public let repoId: URL
  public let moduleId: String
  
  public init(repoId: URL, moduleId: String) {
    self.repoId = repoId
    self.moduleId = moduleId
  }
}

public struct PlaylistCache: Codable, Equatable, Sendable {
  public static func == (lhs: PlaylistCache, rhs: PlaylistCache) -> Bool {
    lhs.playlist != rhs.playlist || lhs.details != rhs.details || lhs.repoModuleId.moduleId != rhs.repoModuleId.moduleId || lhs.repoModuleId.repoId != rhs.repoModuleId.repoId || lhs.groups != rhs.groups
  }
  
  public var playlist: Playlist
  public var details: Playlist.Details?
  public var repoModuleId: RepoModuleId
  public var groups: [Playlist.Group]?
  
  public init(playlist: Playlist, groups: [Playlist.Group]?, details: Playlist.Details?, repoModuleId: RepoModuleID) {
    self.playlist = playlist
    self.groups = groups
    self.details = details
    self.repoModuleId = .init(repoId: repoModuleId.repoId.rawValue, moduleId: repoModuleId.moduleId.rawValue)
  }
}
