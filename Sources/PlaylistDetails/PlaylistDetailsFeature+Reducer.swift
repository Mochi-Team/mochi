//
//  PlaylistDetailsFeature+Reducer.swift
//
//
//  Created ErrorErrorError on 5/19/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import DatabaseClient
import Foundation
import LoggerClient
import ModuleClient
import RepoClient
import SharedModels
import Tagged

// MARK: - PlaylistDetailsFeature.Reducer + Reducer

extension PlaylistDetailsFeature.Reducer: Reducer {
    enum Cancellables: Hashable, CaseIterable {
        case fetchPlaylistDetails
        case fetchPlaylistItems
    }

    @ReducerBuilder<State, Action>
    public var body: some ReducerOf<Self> {
        Case(/Action.view) {
            BindingReducer()
        }

        Reduce { state, action in
            switch action {
            case .view(.didAppear):
                return state.fetchPlaylistContent()

            case .view(.didTappedBackButton):
                return .concatenate(
                    .cancel(ids: Cancellables.allCases),
                    .run {
                        await self.dismiss()
                    }
                )

            case let .view(.didTapVideoItem(groupId, itemId)):
                guard let contents = state.contents.value else {
                    break
                }
                guard let content = contents[groupId: groupId]?.value else {
                    break
                }

                return .send(
                    .delegate(
                        .playbackVideoItem(
                            Playlist.ItemsResponse(
                                content: content,
                                allGroups: contents.allGroups
                            ),
                            repoModuleID: state.repoModuleId,
                            playlist: state.playlist,
                            groupId: groupId,
                            itemId: itemId
                        )
                    )
                )

            case .view(.binding):
                break

            case let .internal(.playlistDetailsResponse(loadable)):
                state.details = loadable

            case let .internal(.playlistItemsResponse(loadable)):
                state.contents = loadable.map { .init($0) }

            case .delegate:
                break
            }
            return .none
        }
    }
}

extension PlaylistDetailsFeature.State {
    mutating func fetchPlaylistContent(_ forced: Bool = false) -> Effect<PlaylistDetailsFeature.Action> {
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
                    try await withTaskCancellation(id: PlaylistDetailsFeature.Reducer.Cancellables.fetchPlaylistDetails) {
                        let value = try await moduleClient.withModule(id: repoModuleId) { module in
                            try await module.playlistDetails(playlistId)
                        }

                        await send(.internal(.playlistDetailsResponse(.loaded(value))))
                    }
                } catch: { error, send in
                    logger.error("\(#function) - \(error)")
                    if let error = error as? ModuleClient.Error {
                        await send(.internal(.playlistDetailsResponse(.failed(error))))
                    } else {
                        await send(.internal(.playlistDetailsResponse(.failed(ModuleClient.Error.unknown()))))
                    }
                }
            )
        }

        if forced || !contents.hasInitialized {
            contents = .loading

            effects.append(
                .run { send in
                    try await withTaskCancellation(id: PlaylistDetailsFeature.Reducer.Cancellables.fetchPlaylistItems) {
                        let value = try await moduleClient.withModule(id: repoModuleId) { module in
                            try await module.playlistVideos(.init(playlistId: playlistId))
                        }

                        await send(.internal(.playlistItemsResponse(.loaded(value))))
                    }
                } catch: { error, send in
                    logger.error("\(#function) - \(error)")
                    if let error = error as? ModuleClient.Error {
                        await send(.internal(.playlistItemsResponse(.failed(error))))
                    } else {
                        await send(.internal(.playlistItemsResponse(.failed(ModuleClient.Error.unknown()))))
                    }
                }
            )
        }

        return .merge(effects)
    }
}

// MARK: - PlaylistDetailsFeature.State.PlaylistContents

public extension PlaylistDetailsFeature.State {
    struct PlaylistContents: Equatable, Sendable {
        public typealias LoadableResponse = Loadable<Playlist.Group.Content>

        public var loadables = [Playlist.Group.ID: LoadableResponse]()
        public let allGroups: [Playlist.Group]
        public var selectedGroupId: Playlist.Group.ID

        public var selectedContent: LoadableResponse {
            loadables[selectedGroupId] ?? .pending
        }

        public var selectedGroup: Playlist.Group? {
            allGroups[id: selectedGroupId]
        }

        public init(_ response: Playlist.ItemsResponse) {
            self.allGroups = response.allGroups
            self.selectedGroupId = response.content.groupId
            loadables[response.content.groupId] = .loaded(response.content)
        }

        public mutating func update(with id: Playlist.Group.ID, loadable: LoadableResponse) {
            loadables[id] = loadable
        }

        public subscript(groupId groupId: Playlist.Group.ID) -> LoadableResponse? {
            loadables[groupId]
        }
    }
}
