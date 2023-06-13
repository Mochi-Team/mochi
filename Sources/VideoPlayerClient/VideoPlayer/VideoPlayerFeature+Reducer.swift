//
//  VideoPlayerFeature+Reducer.swift
//  
//
//  Created ErrorErrorError on 5/26/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import LoggerClient
import ModuleClient

private enum Cancellables: Hashable, CaseIterable {
    case fetchingContents
    case fetchingSources
    case fetchingServer
}

extension VideoPlayerFeature.Reducer: Reducer {
    public var body: some ReducerOf<Self> {
        Scope(state: \.player, action: /Action.internal .. Action.InternalAction.player) {
            PlayerReducer()
        }

        Reduce { state, action in
            switch action {
            case .view(.didAppear):
                let effect = state.fetchGroupsWithContentIfNecessary()
                return .merge(
                    effect,
                    .send(.internal(.player(.initialize)))
                )

            case .view(.didTapBackButton):
                return .merge(
                    .cancel(ids: Cancellables.allCases),
                    .run { _ in
                        await videoPlayerClient.clear()
                        await dismiss()
                    }
                )

            case .view(.didTapMoreButton):
                state.overlay = .more(.episodes)

            case let .view(.didSelectMoreTab(tab)):
                state.overlay = .more(tab)

            case .view(.didTapPlayer):
                state.overlay = state.overlay == .none ? .tools : .none

            case .view(.didTapCloseMoreOverlay):
                state.overlay = .tools

            case let .view(.didTapPlayEpisode(groupId, itemId)):
                state.selected.groupId = groupId
                state.selected.episodeId = itemId
                return state.clearForNewEpisodeIfNeeded()

            case let .view(.didTapSource(sourceId)):
                state.selected.sourceId = sourceId
                return state.clearForChangedServerIfNeeded()

            case let .view(.didTapServer(serverId)):
                state.selected.serverId = serverId
                return state.clearForChangedServerIfNeeded()

            case let .view(.didTapLink(linkId)):
                state.selected.linkId = linkId

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

            case let .internal(.serverResponse(sourceId, response)):
                state.contents.update(with: sourceId, response: response)

                if case let .loaded(response) = response, state.selected.sourceId == sourceId {
                    state.selected.linkId = response.links.first?.id
                    if let link = response.links.first {
                        return .run { _ in
                            try await videoPlayerClient.load(link.url)
                            await videoPlayerClient.play()
                        }
                    }
                } else if case let .failed(error) = response {
                    logger.warning("There was an error retrieving video server response: \(error)")
                }

            case .internal(.player):
                break

            case .delegate:
                break
            }
            return .none
        }
    }
}

extension VideoPlayerFeature.State {
    mutating func clearForNewEpisodeIfNeeded() -> Effect<VideoPlayerFeature.Action> {
        contents.serverLinks = .init()
        return fetchSourcesIfNecessary()
    }

    mutating func clearForChangedServerIfNeeded() -> Effect<VideoPlayerFeature.Action> {
        contents.serverLinks = .init()
        return fetchServerIfNecessary()
    }

    mutating func fetchGroupsWithContentIfNecessary(forced: Bool = false) -> Effect<VideoPlayerFeature.Action> {
        @Dependency(\.moduleClient)
        var moduleClient

        let repoModuleId = repoModuleID
        let playlist = playlist
        let groupId = selected.groupId

        if !contents[groupId: groupId].hasInitialized {
            self.contents.update(with: groupId, response: .loading)
            return .run { send in
                try await withTaskCancellation(id: Cancellables.fetchingContents, cancelInFlight: true) {
                    let value = try await moduleClient.withModule(id: repoModuleId) { module in
                        try await module.playlistVideos(
                            .init(
                                playlistId: playlist.id,
                                playlistItemGroup: groupId
                            )
                        )
                    }

                    await send(.internal(.groupResponse(groupId: groupId, .loaded(value))))
                }
            } catch: { error, send in
                await send(.internal(.groupResponse(groupId: groupId, .failed(error))))
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

        if !contents[episodeId: episodeId].hasInitialized {
            self.contents.update(with: episodeId, response: .loading)
            return .run { send in
                try await withTaskCancellation(id: Cancellables.fetchingSources, cancelInFlight: true) {
                    let value = try await moduleClient.withModule(id: repoModuleId) { module in
                        try await module.playlistVideoSources(
                            .init(
                                playlistId: playlist.id,
                                episodeId: episodeId
                            )
                        )
                    }

                    await send(.internal(.sourcesResponse(episodeId: episodeId, .loaded(value))))
                }
            } catch: { error, send in
                await send(.internal(.sourcesResponse(episodeId: episodeId, .failed(error))))
            }
        }

        return self.fetchServerIfNecessary()
    }

    mutating func fetchServerIfNecessary(forced: Bool = false) -> Effect<VideoPlayerFeature.Action> {
        @Dependency(\.moduleClient)
        var moduleClient

        let repoModuleId = repoModuleID
        let playlist = playlist
        let episodeId = selected.episodeId
        let sourceId = selected.sourceId
        let serverId = selected.serverId

        guard let sourceId else {
            return .none
        }

        guard let serverId else {
            return .none
        }

        if !contents[sourceId: sourceId].hasInitialized {
            contents.update(with: sourceId, response: .loading)
            return .run { send in
                try await withTaskCancellation(id: Cancellables.fetchingServer, cancelInFlight: true) {
                    let value = try await moduleClient.withModule(id: repoModuleId) { module in
                        try await module.playlistVideoServer(
                            .init(
                                playlistId: playlist.id,
                                episodeId: episodeId,
                                sourceId: sourceId,
                                serverId: serverId
                            )
                        )
                    }

                    await send(.internal(.serverResponse(sourceId: sourceId, .loaded(value))))
                }
            } catch: { error, send in
                await send(.internal(.serverResponse(sourceId: sourceId, .failed(error))))
            }
        }

        return .none
    }
}
