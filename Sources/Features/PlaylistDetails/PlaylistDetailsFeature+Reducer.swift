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
import RepoClient
import SharedModels
import Tagged

// MARK: - PlaylistDetailsFeature + Reducer

extension PlaylistDetailsFeature {
    enum Cancellables: Hashable, CaseIterable {
        case fetchPlaylistDetails
    }

    @ReducerBuilder<State, Action>
    public var body: some ReducerOf<Self> {
        Case(/Action.view) {
            BindingReducer()
        }

        Scope(state: \.content, action: /Action.InternalAction.content) {
            ContentCore()
        }

        Reduce { state, action in
            switch action {
            case .view(.didAppear):
                return state.fetchPlaylistDetails()

            case .view(.didTappedBackButton):
                return .concatenate(
                    state.content.clear(),
                    .merge(Cancellables.allCases.map { .cancel(id: $0) }),
                    .run { await self.dismiss() }
                )

            case .view(.didTapToRetryDetails):
                return state.fetchPlaylistDetails(forced: true)

            case .view(.didTapOnReadMore):
                state.destination = .readMore(
                    .init(
                        title: state.playlist.title ?? "No Title",
                        description: state.details.value?.contentDescription ?? "No Description Available"
                    )
                )

            case let .view(.didTapVideoItem(group, page, itemId)):
                guard state.content.value != nil else {
                    break
                }

                return .send(
                    .delegate(
                        .playbackVideoItem(
                            .init(contents: [], allGroups: []),
                            repoModuleID: state.repoModuleId,
                            playlist: state.playlist,
                            group: group,
                            paging: page,
                            itemId: itemId
                        )
                    )
                )

            case let .view(.didTapContentGroup(group)):
                return state.content.fetchPlaylistContentIfNecessary(state.repoModuleId, state.playlist.id, group)

            case let .view(.didTapContentGroupPage(group, page)):
                return state.content.fetchPlaylistContentIfNecessary(state.repoModuleId, state.playlist.id, group, page)

            case .view(.binding):
                break

            case .internal(.destination):
                break

            case let .internal(.playlistDetailsResponse(loadable)):
                state.details = loadable

            case .internal(.content):
                break

            case .delegate:
                break
            }
            return .none
        }
        .ifLet(\.$destination, action: /Action.internal .. Action.InternalAction.destination) {
            PlaylistDetailsFeature.Destination()
        }
    }
}

extension PlaylistDetailsFeature.State {
    mutating func fetchPlaylistDetails(forced: Bool = false) -> Effect<PlaylistDetailsFeature.Action> {
        @Dependency(\.databaseClient)
        var databaseClient

        @Dependency(\.moduleClient)
        var moduleClient

        @Dependency(\.logger)
        var logger

        var effects = [Effect<PlaylistDetailsFeature.Action>]()

        let playlistId = playlist.id
        let repoModuleId = repoModuleId

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

        effects.append(content.fetchPlaylistContentIfNecessary(repoModuleId, playlistId, forced: forced))
        return .merge(effects)
    }
}
