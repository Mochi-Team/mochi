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
import PlayerClient
import SharedModels

// MARK: - Cancellables

private enum Cancellables: Hashable, CaseIterable {
    case fetchingContents
    case fetchingSources
    case fetchingServer
}

// MARK: - VideoPlayerFeature.Reducer + Reducer

extension VideoPlayerFeature.Reducer: Reducer {
    public var body: some ReducerOf<Self> {
        Scope(state: \.player, action: /Action.internal .. Action.InternalAction.player) {
            PlayerFeature.Reducer()
        }

        Reduce { state, action in
            switch action {
            case .view(.didAppear):
                return state.fetchGroupsWithContentIfNecessary()

            case .view(.didTapBackButton):
                return .merge(
                    .cancel(ids: Cancellables.allCases),
                    .run { _ in
                        await playerClient.clear()
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
                return state.clearForNewEpisodeIfNeeded(groupId, itemId)

            case let .view(.didTapSource(sourceId)):
                return state.clearForChangedSourceIfNeeded(sourceId)

            case let .view(.didTapServer(serverId)):
                return state.clearForChangedServerIfNeeded(serverId)

            case let .view(.didTapLink(linkId)):
                return state.clearForChangedLinkIfNeeded(linkId)

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
                            try await playerClient.load(link.url)
                            await playerClient.play()
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

public extension VideoPlayerFeature.State {
    mutating func clearForNewPlaylistIfNeeded(
        repoModuleID: RepoModuleID,
        playlist: Playlist,
        groupId: Playlist.Group.ID,
        episodeId: Playlist.Item.ID
    ) -> Effect<VideoPlayerFeature.Action> {
        @Dependency(\.playerClient)
        var playerClient

        if repoModuleID != self.repoModuleID ||
            playlist.id != self.playlist.id ||
            groupId != selected.groupId ||
            episodeId != selected.episodeId {
            self.repoModuleID = repoModuleID
            self.playlist = playlist
            selected.groupId = groupId
            selected.episodeId = episodeId
            selected.serverId = nil
            selected.linkId = nil
            selected.sourceId = nil
            contents.allGroups = .pending
            contents.groups.removeAll()
            contents.serverLinks.removeAll()
            contents.sources.removeAll()
            return .merge(
                .run { await playerClient.clear() },
                fetchGroupsWithContentIfNecessary()
            )
        }

        return .none
    }

    mutating func clearForNewEpisodeIfNeeded(
        _ groupId: Playlist.Group.ID,
        _ episodeId: Playlist.Item.ID
    ) -> Effect<VideoPlayerFeature.Action> {
        @Dependency(\.playerClient)
        var playerClient

        if selected.groupId != groupId || selected.episodeId != episodeId {
            selected.groupId = groupId
            selected.episodeId = episodeId
            selected.sourceId = nil
            selected.serverId = nil
            selected.linkId = nil
            contents.serverLinks = .init()
            return .merge(
                fetchSourcesIfNecessary(),
                .run {
                    await playerClient.clear()
                }
            )
        }
        return .none
    }

    mutating func clearForChangedSourceIfNeeded(_ sourceId: Playlist.EpisodeSource.ID) -> Effect<VideoPlayerFeature.Action> {
        @Dependency(\.playerClient)
        var playerClient

        if selected.sourceId != sourceId {
            selected.sourceId = sourceId

            if let sources = contents[episodeId: selected.episodeId].value {
                selected.serverId = sources.first { $0.id == sourceId }?.servers.first?.id
            } else {
                selected.serverId = nil
            }
            selected.linkId = nil
            contents.serverLinks[sourceId] = nil

            return .merge(
                fetchSourcesIfNecessary(),
                .run {
                    await playerClient.clear()
                }
            )
        }
        return .none
    }

    mutating func clearForChangedServerIfNeeded(_ serverId: Playlist.EpisodeServer.ID) -> Effect<VideoPlayerFeature.Action> {
        @Dependency(\.playerClient)
        var playerClient

        selected.serverId = serverId
        selected.linkId = nil
        selected.sourceId.flatMap { contents.serverLinks[$0] = nil }

        return .merge(
            fetchServerIfNecessary(),
            .run {
                await playerClient.clear()
            }
        )
    }

    mutating func clearForChangedLinkIfNeeded(_ linkId: Playlist.EpisodeServer.Link.ID) -> Effect<VideoPlayerFeature.Action> {
        @Dependency(\.playerClient)
        var playerClient

        selected.linkId = linkId
        if let sourceId = selected.sourceId {
            if let link = contents.serverLinks[sourceId]?.value?.links.first(where: { $0.id == linkId }) {
                return .run { _ in
                    await playerClient.pause()
                    try await playerClient.load(link.url)
                    await playerClient.play()
                }
            }
        }
        return .none
    }

    mutating func fetchGroupsWithContentIfNecessary(forced: Bool = false) -> Effect<VideoPlayerFeature.Action> {
        @Dependency(\.moduleClient)
        var moduleClient

        let repoModuleId = repoModuleID
        let playlist = playlist
        let groupId = selected.groupId

        if forced || !contents[groupId: groupId].hasInitialized {
            contents.update(with: groupId, response: .loading)
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

        return fetchSourcesIfNecessary()
    }

    mutating func fetchSourcesIfNecessary(forced: Bool = false) -> Effect<VideoPlayerFeature.Action> {
        @Dependency(\.moduleClient)
        var moduleClient

        let repoModuleId = repoModuleID
        let playlist = playlist
        let episodeId = selected.episodeId

        if forced || !contents[episodeId: episodeId].hasInitialized {
            contents.update(with: episodeId, response: .loading)
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

        return fetchServerIfNecessary()
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

        if forced || !contents[sourceId: sourceId].hasInitialized {
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
