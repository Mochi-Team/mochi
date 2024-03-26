//
//  PlaylistDetailsFeature+Reducer.swift
//
//
//  Created ErrorErrorError on 5/19/23.
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
        return state.fetchPlaylistDetails()

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

      case .view(.binding):
        break

      case .internal(.destination):
        break

      case let .internal(.playlistDetailsResponse(loadable)):
        state.details = loadable

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
