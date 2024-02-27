//
//  PlaylistHistory+.swift
//
//
//  Created by DeNeRr on 31.01.2024.
//

import Foundation
import Tagged

// MARK: - PlaylistHistory + Identifiable

extension PlaylistHistory: Identifiable {
  public var id: Tagged<Self, String?> { .init(playlistID) }
  
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
}
