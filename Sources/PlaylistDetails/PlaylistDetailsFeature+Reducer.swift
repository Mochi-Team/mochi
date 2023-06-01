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
                return .run {
                    await self.dismiss()
                }

            case .view(.didDissapear):
                return .cancel(ids: Cancellables.allCases)

            case .view(.binding):
                break

            case let .internal(.playlistDetailsResponse(loadable)):
                state.details = loadable

            case let .internal(.playlistItemsResponse(loadable)):
                state.contents = loadable.mapValue { .init($0) }
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

        let playlistId = self.playlist.id
        let repoModuleId = self.repoModuleId

        if forced || !self.details.hasInitialized {
            self.details = .loading

            effects.append(
                .run { send in
                    try await withTaskCancellation(id: PlaylistDetailsFeature.Reducer.Cancellables.fetchPlaylistDetails) {
                        guard let repo = try await databaseClient.fetch(.all.where(\Repo.$baseURL == repoModuleId.repoId.rawValue)).first else {
                            throw ModuleClient.Error.unknown()
                        }

                        guard let module = repo.modules[id: repoModuleId.moduleId] else {
                            throw ModuleClient.Error.unknown()
                        }

                        try await send(.internal(.playlistDetailsResponse(.loaded(moduleClient.getPlaylistDetails(module, playlistId)))))
                    }
                } catch: { error, send in
                    logger.error("\(#function) - \(error)")
                    if let error = error as? ModuleClient.Error {
                        await send(.internal(.playlistDetailsResponse(.failed(error))))
                    } else {
                        await send(.internal(.playlistDetailsResponse(.failed(.unknown()))))
                    }
                }
            )
        }

        if forced || !self.contents.hasInitialized {
            self.contents = .loading

            effects.append(
                .run { send in
                    try await withTaskCancellation(id: PlaylistDetailsFeature.Reducer.Cancellables.fetchPlaylistItems) {
                        guard let repo = try await databaseClient.fetch(.all.where(\Repo.$baseURL == repoModuleId.repoId.rawValue)).first else {
                            throw ModuleClient.Error.unknown()
                        }

                        guard let module = repo.modules[id: repoModuleId.moduleId] else {
                            throw ModuleClient.Error.unknown()
                        }

                        try await send(
                            .internal(
                                .playlistItemsResponse(
                                    .loaded(
                                        moduleClient.getPlaylistVideos(
                                            module,
                                            .init(playlistId: playlistId)
                                        )
                                    )
                                )
                            )
                        )
                    }
                } catch: { error, send in
                    logger.error("\(#function) - \(error)")
                    if let error = error as? ModuleClient.Error {
                        await send(.internal(.playlistItemsResponse(.failed(error))))
                    } else {
                        await send(.internal(.playlistItemsResponse(.failed(.unknown()))))
                    }
                }
            )
        }

        return .merge(effects)
    }
}

extension PlaylistDetailsFeature.State {
    public struct PlaylistContents: Equatable, Sendable {
        public typealias LoadableResponse = Loadable<Playlist.Group.Content, ModuleClient.Error>

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
            allGroups = response.allGroups
            selectedGroupId = response.content.groupId
            loadables[response.content.groupId] = .loaded(response.content)
        }

        public mutating func update(with id: Playlist.Group.ID, loadable: LoadableResponse) {
            loadables[id] = loadable
        }
    }
}
