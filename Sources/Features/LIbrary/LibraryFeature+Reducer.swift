//
//  LibraryFeature+Reducer.swift
//
//
//  Created by MochiTeam on 09.04.2024.
//

import Architecture
import ComposableArchitecture
import Foundation
import SharedModels
import OfflineManagerClient
import FileClient

// MARK: - LibraryFeature + Reducer

extension LibraryFeature: Reducer {
  public var body: some ReducerOf<Self> {
    Scope(state: \.self, action: \.view) {
      BindingReducer()
    }

    Reduce { state, action in
      switch action {
        case .view(.didAppear):
          return .run { send in
            try fileClient.initializeLibrary()
            await send(.internal(.observeDirectory(try fileClient.retrieveLibraryDirectory(root: .playlistCache))))
          }

        case let .view(.didTapPlaylist(fileMetadata)):
          state.path.append(.playlistDetails(.init(
            content: .init(
              repoModuleId: .init(repoId: .init(rawValue: fileMetadata.repoModuleId.repoId), moduleId: .init(rawValue: fileMetadata.repoModuleId.moduleId)),
              playlist: fileMetadata.playlist,
              cachedGroups: fileMetadata.groups
            ),
            details: fileMetadata.details != nil ? .loaded(fileMetadata.details!) : .pending)))
            
        case let .view(.didTapDownloadQueue):
          state.path.append(.downloadQueue(.init()))

        case let .view(.didTapRemoveBookmark(cache)):
          return .run { _ in
            try await offlineManagerClient.remove(.cache, cache.playlist.id.rawValue, nil);
          }

        case let .view(.didTapRemovePlaylist(cache)):
          return .run { _ in
            try await offlineManagerClient.remove(.all, cache.playlist.id.rawValue, nil);
          }

        case .view(.didtapOpenLibraryCollectionSheet):
          break

        case .view(.didTapShowDownloadedOnly):
          let lastOfflineOnlyState = !state.showOfflineOnly
          state.showOfflineOnly = !state.showOfflineOnly
          return .run { send in
            await send(.internal(.observeDirectory(try fileClient.retrieveLibraryDirectory(root: lastOfflineOnlyState ? .downloaded : .playlistCache))))
          }


        case .view(.binding(\.$searchValue)):
          if let playlists = state.playlists.value {
            state.searchedPlaylists = playlists.filter { $0.playlist.title?.lowercased().contains(state.searchValue.lowercased()) ?? false }
          }

        case .view(.binding):
        break

        case .view:
          break

        case let .internal(.path(.element(_, .playlistDetails(.delegate(.playbackVideoItem(items, id, playlist, group, variant, paging, itemId)))))):
          return .run { send in
            await send(
              .delegate(
                .playbackVideoItem(
                  items,
                  repoModuleId: id,
                  playlist: playlist,
                  group: group,
                  variant: variant,
                  paging: paging,
                  itemId: itemId
                )
              )
            )
          }

        case let .internal(.observeDirectory(directory)):
          return .run { send in
            for try await playlistIds in try fileClient.observeDirectory(directory) {
              let playlists = try playlistIds.flatMap {
                if let json = try fileClient.retrieveLibraryMetadata(root: .playlistCache, encodedPlaylist: $0) {
                  var cache: PlaylistCache = try JSONDecoder().decode(PlaylistCache.self, from: json)
                  if let image = fileClient.getLibraryPlaylistImage(playlist: cache.playlist.id.rawValue) {
                    cache.playlist.posterImage = image
                    cache.playlist.bannerImage = image
                  }
                  return cache
                }
                return nil
              }
              await send(.internal(.playlistsDidLoad(playlists)))
            }
          }

        case let .internal(.playlistsDidLoad(playlists)):
          state.playlists = .loaded(playlists.sorted(by: { $0.playlist.title ?? "" < $1.playlist.title ?? "" }))
        case .internal:
          break
        case .delegate:
          break
      }
      return .none
    }
    .forEach(\.path, action: \.internal.path) {
      Path()
    }
  }
}
