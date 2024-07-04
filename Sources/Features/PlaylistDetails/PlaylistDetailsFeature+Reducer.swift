//
//  PlaylistDetailsFeature+Reducer.swift
//
//
//  Created MochiTeam on 5/19/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import ContentCore
import DatabaseClient
import Foundation
import LoggerClient
import ModuleClient
import PlaylistHistoryClient
import RepoClient
import SharedModels
import Tagged

// MARK: - PlaylistDetailsFeature + Reducer

extension PlaylistDetailsFeature {
  enum Cancellables: Hashable, CaseIterable {
    case fetchPlaylistDetails
  }

  @ReducerBuilder<State, Action> public var body: some ReducerOf<Self> {
    Case(/Action.view) {
      BindingReducer()
    }

    Scope(state: \.content, action: \.internal.content) {
      ContentCore()
    }

    Reduce { state, action in
      switch action {
      case .view(.onTask):
        @Dependency(\.fileClient) var fileClient
        
        let playlistId = state.playlist.id.rawValue
        let cacheDirectory = try? fileClient.retrieveLibraryDirectory(root: .playlistCache)
        let downloadsDirectory = try? fileClient.retrieveLibraryDirectory(root: .downloaded)
        return .merge(
          state.fetchPlaylistDetails(),
          .run { send in
            if let cacheDirectory = cacheDirectory, fileClient.fileExists(cacheDirectory.path) {
              for await _ in try fileClient.observeDirectory(cacheDirectory) {
                let dir = try fileClient.retrieveLibraryDirectory(root: .playlistCache, playlist: playlistId)
                await send(.internal(.setBookmark(FileManager.default.fileExists(atPath: dir.path))))
              }
            }
          },
          .run { send in
            if let downloadsDirectory = downloadsDirectory, fileClient.fileExists(downloadsDirectory.path) {
              for await _ in try fileClient.observeDirectory(downloadsDirectory) {
                if let dir = try? fileClient.retrieveLibraryDirectory(root: .downloaded, playlist: playlistId) {
                  let isEmpty = (try? FileManager.default.contentsOfDirectory(atPath: dir.path).isEmpty) ?? true
                  await send(.internal(.setHasDownloadedContent(!isEmpty)))
                }
              }
            }
          }
        )

      case .view(.didTappedBackButton):
        return .run { await self.dismiss() }

      case .view(.didTapToRetryDetails):
        return state.fetchPlaylistDetails(forced: true)

      case .view(.didTapOnReadMore):
        state.destination = .readMore(
          .init(
            title: state.playlist.title ?? "No Title",
            description: state.details.value?.synopsis ?? "No Description Available"
          )
        )
        
      case .view(.didTapAddToLibrary):
        let playlist = state.playlist
        if (state.isInLibrary) {
          return .run {
            try await offlineManagerClient.remove(.cache, playlist.id.rawValue, nil)
          }
        }
        let repoModuleId = state.content.repoModuleId
        let details = state.details.value
        let groups = state.content.groups.value
        return .run {
          try await offlineManagerClient.cache(.init(
            groups: groups,
            playlist: playlist,
            details: details,
            repoModuleId: repoModuleId
          ))
        }
        
      case .view(.didTapRemoveDownloads):
        let playlist = state.playlist
          return .run {
            try await offlineManagerClient.remove(.download, playlist.id.rawValue, nil)
          }

      case .view(.binding):
        break

      case .internal(.destination):
        break

      case let .internal(.playlistDetailsResponse(loadable)):
        state.details = loadable
        break
        
      case let .internal(.content(.downloadSelection(.presented(.selection(.download(source, server, link, subtitles, skipTimes, episode, headers)))))):
        let playlist = state.playlist
        let details = state.details.value
        let groups = state.content.groups.value
        let repoModuleId = state.content.repoModuleId
        return .run { send in
          try await offlineManagerClient.download(.init(
            episodeMetadata: .init(link: link, source: source, subtitles: subtitles, server: server, skipTimes: skipTimes),
            headers: headers,
            episode: episode,
            groups: groups,
            playlist: playlist,
            details: details,
            repoModuleId: repoModuleId
          ))
        }
          
      case let .internal(.setBookmark(bookmarked)):
        state.isInLibrary = bookmarked
          
      case let .internal(.setHasDownloadedContent(isDownloaded)):
        state.hasDownloadedContent = isDownloaded
        
      case let .internal(.content(.updateCache(newCache))):
        if (!state.isInLibrary) {
          break
        }
        let playlist = state.playlist
        let details = state.details.value
        let repoModuleId = state.content.repoModuleId
        return .run { send in
          try await offlineManagerClient.cache(.init(groups: newCache, playlist: playlist, details: details, repoModuleId: repoModuleId))
        }
        

      case let .internal(.content(.didTapPlaylistItem(groupId, variantId, pageId, itemId, _))):
        guard state.content.groups.value != nil else {
          break
        }

        switch state.content.playlist.type {
        case .video:
          return .send(
            .delegate(
              .playbackVideoItem(
                .init(),
                repoModuleId: state.content.repoModuleId,
                playlist: state.content.playlist,
                group: groupId,
                variant: variantId,
                paging: pageId,
                itemId: itemId
              )
            )
          )
        default:
          break
        }

      case .internal(.content):
        break

      case .delegate:
        break
      }
      return .none
    }
    .ifLet(\.$destination, action: \.internal.destination) {
      PlaylistDetailsFeature.Destination()
    }
  }
}

extension PlaylistDetailsFeature.State {
  mutating func fetchPlaylistDetails(forced: Bool = false) -> Effect<PlaylistDetailsFeature.Action> {
    @Dependency(\.databaseClient) var databaseClient
    @Dependency(\.moduleClient) var moduleClient

    var effects = [Effect<PlaylistDetailsFeature.Action>]()

    let playlistId = playlist.id
    let repoModuleId = content.repoModuleId

    if forced || !details.hasInitialized {
      details = .loading

      effects.append(
        .run { send in
          try await withTaskCancellation(id: PlaylistDetailsFeature.Cancellables.fetchPlaylistDetails) {
            let value = try await moduleClient.withModule(id: repoModuleId) { module in
              try await module.playlistDetails(playlistId)
            }

            await send(.internal(.playlistDetailsResponse(.loaded(value))))
          }
        } catch: { error, send in
          logger.error("\(#function) - \(error)")
          await send(.internal(.playlistDetailsResponse(.failed(error))))
        }
      )
    }

    effects.append(content.fetchContent(forced: forced).map { .internal(.content($0)) })
    return .merge(effects)
  }
}
