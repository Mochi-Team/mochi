//
//  AppFeature+Reducer.swift
//
//
//  Created by ErrorErrorError on 4/6/23.
//
//

import Architecture
import ComposableArchitecture
import DatabaseClient
import Discover
import ModuleLists
import Repos
import Settings
import VideoPlayer

extension AppFeature: Reducer {
  public var body: some ReducerOf<Self> {
    Scope(state: \.appDelegate, action: \.internal.appDelegate) {
      AppDelegateFeature()
    }

    Reduce { state, action in
      switch action {
      case .view(.didAppear):
        break

      case let .view(.didSelectTab(tab)):
        if state.selected == tab {
          switch tab {
          case .discover:
            if !state.discover.path.isEmpty {
              state.discover.path.removeAll()
            } else if state.discover.search != nil {
              state.discover.search = nil
            }
          case .repos:
            state.repos.path.removeAll()
          case .settings:
            state.settings.path.removeAll()
          }
        } else {
          state.selected = tab
        }

      case .internal(.appDelegate):
        break

      case let .internal(.discover(.delegate(.playbackVideoItem(_, repoModuleId, playlist, group, variant, paging, itemId)))):
        let effect = state.videoPlayer?.clearForNewPlaylistIfNeeded(
          repoModuleId: repoModuleId,
          playlist: playlist,
          groupId: group,
          variantId: variant,
          pageId: paging,
          episodeId: itemId
        )
        .map { Action.internal(.videoPlayer(.presented($0))) }

        if let effect {
          return effect
        } else {
          state.videoPlayer = .init(
            repoModuleId: repoModuleId,
            playlist: playlist,
            group: group,
            variant: variant,
            page: paging,
            episodeId: itemId
          )
        }

      case .internal(.discover):
        break

      case .internal(.repos):
        break

      case .internal(.settings):
        break

      case .internal(.videoPlayer(.dismiss)):
        return .run { _ in await playerClient.clear() }

      case .internal(.videoPlayer):
        break
      }
      return .none
    }
    .ifLet(\.$videoPlayer, action: \.internal.videoPlayer) {
      VideoPlayerFeature()
    }

    Scope(state: \.discover, action: \.internal.discover) {
      DiscoverFeature()
    }

    Scope(state: \.repos, action: \.internal.repos) {
      ReposFeature()
    }

    Scope(state: \.settings, action: \.internal.settings) {
      SettingsFeature()
    }
  }
}
