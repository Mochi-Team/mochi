//
//  Models.swift
//
//
//  Created by MochiTeam on 06.04.2024.
//

import Foundation
import SharedModels
import Tagged

extension OfflineManagerClient {
  public enum Error: Swift.Error, Equatable, Sendable {
    case failedToGetPlaylistId
    case failedToCreateDownloadTask
    case failedToGenerateHLS
  }
  
  public enum RemoveType {
    case cache
    case download
    case all
  }
  
  public struct DownloadAsset: Equatable, Sendable {
    public let episodeMetadata: EpisodeMetadata
    public let episode: Playlist.Item
    public let headers: [String: String]
    public let groups: [Playlist.Group]?
    public let playlist: Playlist
    public let details: Playlist.Details?
    public let repoModuleId: RepoModuleID
    
    public init(episodeMetadata: EpisodeMetadata, headers: [String: String], episode: Playlist.Item, groups: [Playlist.Group]?, playlist: Playlist, details: Playlist.Details?, repoModuleId: RepoModuleID) {
      self.episodeMetadata = episodeMetadata
      self.headers = headers
      self.episode = episode
      self.groups = groups
      self.playlist = playlist
      self.details = details
      self.repoModuleId = repoModuleId
    }
  }
  
  public struct CacheAsset: Equatable, Sendable {
    public let groups: [Playlist.Group]?
    public let playlist: Playlist
    public let details: Playlist.Details?
    public let repoModuleId: RepoModuleID
    
    public init(groups: [Playlist.Group]?, playlist: Playlist, details: Playlist.Details?, repoModuleId: RepoModuleID) {
      self.playlist = playlist
      self.details = details
      self.groups = groups
      self.repoModuleId = repoModuleId
    }
  }
  
  public struct DownloadingItem: Identifiable, Sendable, Equatable, Hashable {
    public let id: URL
    public var percentComplete: Double
    public let image: URL
    public let playlistName: String
    public let title: String
    public let epNumber: Double
    public let taskId: Int
    public var status: StatusType
    
    public init(id: URL, percentComplete: Double, image: URL, playlistName: String, title: String, epNumber: Double, taskId: Int, status: StatusType) {
      self.id = id
      self.percentComplete = percentComplete
      self.image = image
      self.playlistName = playlistName
      self.title = title
      self.epNumber = epNumber
      self.taskId = taskId
      self.status = status
    }
  }
  
  public enum StatusType: Sendable {
    case downloading
    case suspended
    case finished
    case cancelled
    case error
  }
  
  public struct DownloadingAsset: Hashable {
    public let url: URL
    public let playlist: Playlist
    public let episode: Playlist.Item
    public let metadata: EpisodeMetadata
    public var location: URL?
    public var percentage: Double = 0
    public var taskId: Int
    public var status: StatusType
    
    public init(url: URL, playlist: Playlist, episode: Playlist.Item, metadata: EpisodeMetadata, location: URL? = nil, taskId: Int, status: StatusType) {
      self.url = url
      self.playlist = playlist
      self.episode = episode
      self.metadata = metadata
      self.location = location
      self.taskId = taskId
      self.status = status
    }
  }
}
