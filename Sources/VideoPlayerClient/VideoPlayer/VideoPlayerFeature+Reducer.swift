//
//  VideoPlayerFeature+Reducer.swift
//  
//
//  Created ErrorErrorError on 5/26/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import ModuleClient

private enum Cancellables: Hashable {
}

extension VideoPlayerFeature.Reducer: Reducer {
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.didAppear):
                return state.fetchGroupsWithContentIfNecessary()

            case .view(.didTapBackButton):
                return .run {
                    await dismiss()
                }

            case .view(.didTapMoreButton):
                state.overlay = .more(.episodes)

            case let .view(.didSelectMoreTab(tab)):
                state.overlay = .more(tab)

            case .view(.didTapPlayer):
                state.overlay = state.overlay == .none ? .tools : .none

            case .view(.didTapCloseMoreOverlay):
                state.overlay = .tools

            case .view(.didTapPlayButton):
                return .run {
//                    await videoPlayerClient.play()
                }

            case let .view(.didTapPlayEpisode(groupId, itemId)):
                state.selected.groupId = groupId
                state.selected.episodeId = itemId

            case let .view(.didTapSource(sourceId)):
                state.selected.sourceId = sourceId

            case let .view(.didTapServer(serverId)):
                state.selected.serverId = serverId

            case let .internal(.groupResponse(groupId, .loaded(response))):
                state.contents.update(with: groupId, response: .loaded(response))
                return state.fetchSourcesIfNecessary()

            case let .internal(.groupResponse(groupId, response)):
                state.contents.update(with: groupId, response: response)

            case let .internal(.sourcesResponse(episodeId, .loaded(response))):
                state.contents.update(with: episodeId, response: .loaded(response))
                if state.selected.sourceId == nil {
                    state.selected.sourceId = response.first?.id
                }
                if state.selected.serverId == nil {
                    state.selected.serverId = response.first?.servers.first?.id
                }
                return state.fetchServerIfNecessary()

            case let .internal(.sourcesResponse(episodeId, response)):
                state.contents.update(with: episodeId, response: response)

            case let .internal(.serversResponse(episodeId, sourceId, .loaded(response))):
                break

            case let .internal(.serversResponse(episodeId, sourceId, response)):
                break

            case .delegate:
                break
            }
            return .none
        }
    }
}

extension VideoPlayerFeature.State {
    mutating func fetchGroupsWithContentIfNecessary(forced: Bool = false) -> Effect<VideoPlayerFeature.Action> {
        @Dependency(\.moduleClient)
        var moduleClient

        let repoModuleId = repoModuleID
        let playlist = playlist
        let groupId = selected.groupId

        if !contents[groupId: groupId].hasInitialized {
            self.contents.update(with: groupId, response: .loading)
            return .run { send in
                let value = try await moduleClient.withModule(id: repoModuleId) { module in
                    try await module.playlistVideos(
                        .init(
                            playlistId: playlist.id,
                            playlistItemGroup: groupId
                        )
                    )
                }

                await send(.internal(.groupResponse(groupId: groupId, .loaded(value))))
            } catch: { error, send in
                if let error = error as? ModuleClient.Error {
                    await send(.internal(.groupResponse(groupId: groupId, .failed(error))))
                } else {
                    await send(.internal(.groupResponse(groupId: groupId, .failed(.unknown()))))
                }
            }
        }

        return self.fetchSourcesIfNecessary()
    }

    mutating func fetchSourcesIfNecessary(forced: Bool = false) -> Effect<VideoPlayerFeature.Action> {
        @Dependency(\.moduleClient)
        var moduleClient

        let repoModuleId = repoModuleID
        let playlist = playlist
        let episodeId = selected.episodeId

        if contents.sources[episodeId] == nil || contents.sources[episodeId]?.hasInitialized == false {
            self.contents.update(with: episodeId, response: .loading)
            return .run { send in
                let value = try await moduleClient.withModule(id: repoModuleId) { module in
                    try await module.playlistVideoSources(
                        .init(
                            playlistId: playlist.id,
                            episodeId: episodeId
                        )
                    )
                }

                await send(.internal(.sourcesResponse(episodeId: episodeId, .loaded(value))))
            } catch: { error, send in
                if let error = error as? ModuleClient.Error {
                    await send(.internal(.sourcesResponse(episodeId: episodeId, .failed(error))))
                } else {
                    await send(.internal(.sourcesResponse(episodeId: episodeId, .failed(.unknown()))))
                }
            }
        }

        return self.fetchServerIfNecessary()
    }

    mutating func fetchServerIfNecessary(forced: Bool = false) -> Effect<VideoPlayerFeature.Action> {
        @Dependency(\.moduleClient)
        var moduleClient

//        let repoModuleId = repoModuleID
//        let playlist = playlist
//        let groupId = selected.groupId
//        let episodeId = selected.episodeId

        return .none
    }
}
