//
//  DownloadSection.swift
//
//
//  DownloadSelection by MochiTeam on 15.04.2024.
//

import Foundation
import OfflineManagerClient
import ComposableArchitecture
import SharedModels

private enum Cancellable: Hashable, CaseIterable {
  case fetchingSources
  case fetchingServer
}


public struct DownloadSelection: Reducer {
  public enum State: Equatable, Sendable {
    case selection(Selection.State)
  }

  public enum Action: Equatable, Sendable {
    case selection(Selection.Action)
  }

  public var body: some ReducerOf<Self> {
    Scope(state: /State.selection, action: /Action.selection) {
      Selection()
    }
  }

  public struct Selection: Reducer {
    public struct State: Equatable, Sendable {
      public let repoModuleId: RepoModuleID
      public let playlistId: Playlist.ID
      public let episode: Playlist.Item

      public var sources: Loadable<[Playlist.EpisodeSource]>
      public var serverResponse: Loadable<Playlist.EpisodeServerResponse>

      public var selectedSource: Playlist.EpisodeSource? = nil
      public var selectedServer: Playlist.EpisodeServer? = nil
      public var selectedQuality: Playlist.EpisodeServer.Link? = nil
      public var selectedSubtitle: Playlist.EpisodeServer.Subtitle? = nil

      public init(repoModuleId: RepoModuleID, playlistId: Playlist.ID, episode: Playlist.Item, sources: Loadable<[Playlist.EpisodeSource]> = .pending, serverResponse: Loadable<Playlist.EpisodeServerResponse> = .pending) {
        self.repoModuleId = repoModuleId
        self.playlistId = playlistId
        self.episode = episode
        self.sources = sources
        self.serverResponse = serverResponse
      }
    }

    public enum Action: Equatable, Sendable {
      case didAppear
      case sourcesResponse(Loadable<[Playlist.EpisodeSource]>)
      case selectSource(Playlist.EpisodeSource)
      case selectServer(Playlist.EpisodeServer)
      case selectQuality(Playlist.EpisodeServer.Link)
      case selectSubtitle(Playlist.EpisodeServer.Subtitle)
      case serverResponse(Loadable<Playlist.EpisodeServerResponse>)
      case download(Playlist.EpisodeSource, Playlist.EpisodeServer, Playlist.EpisodeServer.Link, [Playlist.EpisodeServer.Subtitle], [Playlist.EpisodeServer.SkipTime], Playlist.Item, [String: String])
    }

    public var body: some ReducerOf<Self> {
      Reduce { state, action in
        switch action {
          case .didAppear:
            @Dependency(\.moduleClient) var moduleClient
            let episode = state.episode
            let playlistId = state.playlistId
            let repoModuleId = state.repoModuleId
            return .run { send in
              try await withTaskCancellation(id: Cancellable.fetchingSources, cancelInFlight: true) {
                let value = try await moduleClient.withModule(id: repoModuleId) { module in
                  try await module.playlistEpisodeSources(
                    .init(
                      playlistId: playlistId,
                      episodeId: episode.id
                    )
                  )
                }
                await send(.sourcesResponse(.loaded(value)))
              }
            }
          case let .sourcesResponse(sources):
            state.sources = sources

          case let .serverResponse(serverResponse):
            state.serverResponse = serverResponse

          case let .selectSource(source):
            state.selectedSource = source
            state.serverResponse = .pending
            state.selectedQuality = nil
            state.selectedSubtitle = nil

          case let .selectQuality(quality):
            state.selectedQuality = quality

          case let .selectSubtitle(subtitle):
            state.selectedSubtitle = subtitle

          case let .selectServer(server):
            state.serverResponse = .loading
            state.selectedQuality = nil
            state.selectedSubtitle = nil
            guard let source = state.selectedSource else {
              return .none
            }
            let episode = state.episode
            let playlistId = state.playlistId
            let repoModuleId = state.repoModuleId
            @Dependency(\.moduleClient) var moduleClient
            state.selectedServer = server
            return .run { send in
              try await withTaskCancellation(id: Cancellable.fetchingServer, cancelInFlight: true) {
                let value = try await moduleClient.withModule(id: repoModuleId) { module in
                  try await module.playlistEpisodeServer(
                    .init(
                      playlistId: playlistId,
                      episodeId: episode.id,
                      sourceId: source.id,
                      serverId: server.id
                    )
                  )
                }
                await send(.serverResponse(.loaded(value)))
              }
            }

          case .download:
            @Dependency(\.dismiss) var dismiss
            return .run {
              await dismiss()
            }
        }
        return .none
      }
    }
  }
}
