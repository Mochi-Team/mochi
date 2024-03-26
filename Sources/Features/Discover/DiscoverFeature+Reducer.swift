//
//  DiscoverFeature+Reducer.swift
//
//
//  Created by ErrorErrorError on 4/5/23.
//
//

import Architecture
import ComposableArchitecture
import DatabaseClient
import Foundation
import LoggerClient
import ModuleClient
import ModuleLists
import PlaylistDetails
import RepoClient
import Search
import SharedModels
import Tagged

// MARK: - DiscoverFeature

extension DiscoverFeature {
  enum Cancellables: Hashable {
    case fetchDiscoverList
  }

  @ReducerBuilder<State, Action> public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .view(.didAppear):
        if state.section.module != nil {
          break
        }
        guard let moduleId = UserDefaults.standard.string(forKey: "LastSelectedModuleId"),
              let repoId = UserDefaults.standard.url(forKey: "LastSelectedRepoId") else {
          state.section = .home()
          break
        }
        return .run { send in
          try await Task.sleep(nanoseconds: 50_000_000)
          if let repo = try? await databaseClient.fetch(.all.where(\Repo.remoteURL == repoId)).first, let module = repo.modules[id: Module.Manifest.ID(moduleId)]?.manifest {
            await send(.internal(.selectedModule(.init(repoId: Tagged<Repo, URL>(repoId), module: module))))
          } else {
            await send(.internal(.selectedModule(nil)))
          }
        }

      case let .view(.didTapContinueWatching(item)):
        let blankUrl = URL(string: "_blank")!
        return .run { send in
          try? await moduleClient.withModule(id: .init(repoId: Repo.ID(URL(string: item.repoId)!), moduleId: Module.ID(item.moduleId))) { module in

            let options = Playlist.ItemsRequestOptions.page(.init(item.groupId), .init(item.variantId), .init(item.pageId))

            let eps = try? await module.playlistEpisodes(Playlist.ID(rawValue: item.playlistID), options)

            let playlist = Playlist(id: Playlist.ID(rawValue: item.playlistID), title: item.playlistName, posterImage: nil, bannerImage: nil, url: blankUrl, status: .unknown, type: .video)

            try? await playlistHistoryClient.updateDateWatched(.init(repoId: item.repoId, moduleId: item.moduleId, playlistId: playlist.id.rawValue))
            await send(
              .delegate(
                .playbackVideoItem(
                  eps ?? [],
                  repoModuleId: .init(repoId: Repo.ID(URL(string: item.repoId)!), moduleId: Module.ID(item.moduleId)),
                  playlist: playlist,
                  group: .init(item.groupId),
                  variant: .init(item.variantId),
                  paging: .init(item.pageId),
                  itemId: .init(item.epId)
                )
              )
            )
          }
        }

      case let .view(.didTapRemovePlaylistHistory(repoId, moduleId, playlistId)):
        return .run { send in
          if let _ = try? await playlistHistoryClient.removePlaylistHistory(.init(repoId: repoId, moduleId: moduleId, playlistId: playlistId)) {
            await send(.internal(.removeLastWatchedPlaylist(playlistId)))
          }
        }

      case .view(.didTapRetryLoadingModule):
        return state.fetchLatestListings(state.section.module?.module)

      case .view(.didTapOpenModules):
        state.moduleLists = .init()

      case let .view(.didTapPlaylist(playlist)):
        guard let id = state.section.module?.module.id else {
          break
        }
        state.path.append(.playlistDetails(.init(content: .init(repoModuleId: id, playlist: playlist))))

      case .view(.didTapSearchButton):
        if let repoModuleId = state.section.module?.module.id {
          state.path.append(.search(.init(repoModuleId: repoModuleId)))
        }

      case let .view(.didTapViewMoreListing(listingId)):
        guard let id = state.section.module?.module.id else {
          logger.warning("repoModuleID was not set which failed to view more listing")
          break
        }

        guard let listing = state.section.module?.listings.value?[id: listingId] else {
          logger.warning("listing item was not found but trigger tap event")
          break
        }

        state.path.append(.viewMoreListing(.init(repoModuleId: id, listing: listing)))

      case let .internal(.selectedModule(selection)):
        if let selection {
          state.section = .module(.init(module: selection, listings: .pending))
        } else {
          state.section = .home()
        }
        return state.fetchLatestListings(selection)

      case let .internal(.loadedListings(id, loadable)):
        if var moduleState = state.section.module, moduleState.module.repoId == id.repoId, moduleState.module.module.id == id.moduleId {
          moduleState.listings = loadable
          state.section = .module(moduleState)
        }

      case let .internal(.moduleLists(.presented(.delegate(.selectedModule(repoModule))))):
        state.moduleLists = nil
        return .send(.internal(.selectedModule(repoModule)))

      case let .internal(.path(.element(_, .search(.delegate(.playlistTapped(repoModuleId, playlist)))))):
        state.path.append(.playlistDetails(.init(content: .init(repoModuleId: repoModuleId, playlist: playlist))))

      case let .internal(.path(.element(elementId, .viewMoreListing(.didTapPlaylist(playlist))))):
        guard let id = state.path[id: elementId]?.viewMoreListing?.repoModuleId else {
          break
        }
        state.path.append(.playlistDetails(.init(content: .init(repoModuleId: id, playlist: playlist))))

      case let .internal(.path(.element(_, .playlistDetails(.delegate(.playbackVideoItem(items, id, playlist, group, variant, paging, itemId)))))):
        return .send(
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

      case .internal(.onLastWatchedAppear):
        guard let repoModule = state.section.module?.module.id else {
          break
        }

        return .run { send in
          if let history = try? await playlistHistoryClient.fetchForModule(repoModule.repoId.absoluteString, repoModule.moduleId.rawValue) {
            await send(.internal(.updateLastWatched(history)))
          }
        }

      case let .internal(.removeLastWatchedPlaylist(playlistId)):
        state.lastWatched?.removeAll { $0.playlistID == playlistId }

      case let .internal(.updateLastWatched(history)):
        state.lastWatched = history

      case .internal(.moduleLists):
        break

      case let .internal(.showCaptcha(html, hostname)):
        state.solveCaptcha = .solveCaptcha(.init(html: html, hostname: hostname))

      case .internal(.solveCaptcha):
        break

      case .internal(.path):
        break

      case .delegate(.playbackDismissed):
        return .send(.internal(.onLastWatchedAppear))

      case .delegate:
        break
      }
      return .none
    }
    .ifLet(\.$moduleLists, action: \.internal.moduleLists) {
      ModuleListsFeature()
    }
    .ifLet(\.$solveCaptcha, action: \.internal.solveCaptcha) {
      DiscoverFeature.Captcha()
    }
    .forEach(\.path, action: \.internal.path) {
      Path()
    }
  }
}

extension DiscoverFeature.State {
  mutating func fetchLatestListings(_ selectedModule: RepoClient.SelectedModule?) -> Effect<DiscoverFeature.Action> {
    @Dependency(\.moduleClient) var moduleClient

    guard let selectedModule else {
      section = .home(.init())
      return .none
    }

    section = .module(.init(module: selectedModule, listings: .loading))

    let id = selectedModule.id

    return .run { send in
      try await withTaskCancellation(id: DiscoverFeature.Cancellables.fetchDiscoverList) {
        let value = try await moduleClient.withModule(id: id) { module in
          try await module.discoverListings()
        }

        await send(.internal(.onLastWatchedAppear))

        await send(.internal(.loadedListings(id, .loaded(value))))
      }
    } catch: { error, send in
      if let error = error as? ModuleClient.Error {
        if case let .jsRuntime(.requestForbidden(data, hostmame)) = error {
          await send(.internal(.showCaptcha(data, hostmame)))
        }
        await send(.internal(.loadedListings(id, .failed(DiscoverFeature.Error.module(error)))))
      } else {
        await send(.internal(.loadedListings(id, .failed(DiscoverFeature.Error.system(.unknown)))))
      }
    }
  }
}
