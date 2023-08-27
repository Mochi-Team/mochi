//
//  VideoPlayerFeature+Reducer.swift
//
//
//  Created ErrorErrorError on 5/26/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import ContentCore
import LoggerClient
import ModuleClient
import PlayerClient
import SharedModels

// MARK: - Cancellables

private enum Cancellables: Hashable, CaseIterable {
    case delayCloseTab
    case fetchingSources
    case fetchingServer
}

extension VideoPlayerFeature: Reducer {
    public var body: some ReducerOf<Self> {
        Scope(state: \.player, action: /Action.internal .. Action.InternalAction.player) {
            PlayerFeature()
        }

        Scope(state: \.loadables.contents, action: /Action.InternalAction.content) {
            ContentCore()
        }

        Reduce { state, action in
            switch action {
            case .view(.didAppear):
                return state.loadables.contents
                    .fetchPlaylistContentIfNecessary(
                        state.repoModuleID,
                        state.playlist.id,
                        state.selected.group,
                        state.selected.page
                    )

            case .view(.didTapBackButton):
                return state.dismiss()

            case .view(.didTapMoreButton):
                state.overlay = .more(.episodes)
                return .cancel(id: Cancellables.delayCloseTab)

            case let .view(.didSelectMoreTab(tab)):
                state.overlay = .more(tab)
                return .cancel(id: Cancellables.delayCloseTab)

            case .view(.didTapPlayer):
                state.overlay = state.overlay == nil ? .tools : nil
                return state.delayDismissOverlayIfNeeded()

            case .view(.didTapCloseMoreOverlay):
                state.overlay = .tools
                return state.delayDismissOverlayIfNeeded()

            case let .view(.didTapContentGroup(groupId)):
                return state.loadables.contents.fetchPlaylistContentIfNecessary(state.repoModuleID, state.playlist.id, groupId)

            case let .view(.didTapContentGroupPage(groupId, pageId)):
                return state.loadables.contents.fetchPlaylistContentIfNecessary(state.repoModuleID, state.playlist.id, groupId, pageId)

            case let .view(.didTapPlayEpisode(group, page, itemId)):
                state.overlay = .tools
                return state.clearForNewEpisodeIfNeeded(group, page, itemId)

            case let .view(.didTapSource(sourceId)):
                return state.clearForChangedSourceIfNeeded(sourceId)

            case let .view(.didTapServer(serverId)):
                return state.clearForChangedServerIfNeeded(serverId)

            case let .view(.didTapLink(linkId)):
                return state.clearForChangedLinkIfNeeded(linkId)

            case let .view(.didSkipTo(time)):
                let fraction = max(state.player.duration.seconds, 1)
                return .run { _ in
                    await playerClient.seek(time / fraction)
                }

            case .internal(.hideToolsOverlay):
                state.overlay = state.overlay == .tools ? nil : state.overlay

            case .internal(.content(.update(_, _, .loaded))):
                return state.fetchSourcesIfNecessary()

            case let .internal(.sourcesResponse(episodeId, .loaded(response))):
                state.loadables.update(with: episodeId, response: .loaded(response))

                // TODO: Select preferred quality or first link if available
                if state.selected.sourceId == nil {
                    state.selected.sourceId = response.first?.id
                }
                if state.selected.serverId == nil {
                    state.selected.serverId = response.first?.servers.first?.id
                }
                return state.fetchServerIfNecessary()

            case let .internal(.sourcesResponse(episodeId, response)):
                state.loadables.update(with: episodeId, response: response)

            case let .internal(.serverResponse(serverId, response)):
                state.loadables.update(with: serverId, response: response)

                if case let .loaded(response) = response, state.selected.serverId == serverId {
                    // TODO: Select preferred quality or first link if available
                    if let id = response.links.first?.id {
                        return state.clearForChangedLinkIfNeeded(id)
                    }
                } else if case let .failed(error) = response {
                    logger.warning("There was an error retrieving video server response: \(error)")
                }

            case .internal(.player(.delegate(.didStartedSeeking))):
                return .cancel(id: Cancellables.delayCloseTab)

            case .internal(.player(.delegate(.didTapGoForwards))),
                 .internal(.player(.delegate(.didTapGoBackwards))),
                 .internal(.player(.delegate(.didTogglePlayButton))),
                 .internal(.player(.delegate(.didFinishedSeekingTo))):
                return state.delayDismissOverlayIfNeeded()

            case .internal(.player(.delegate(.didTapClosePiP))):
//                return state.dismiss()
                break

            case .internal(.player):
                break

            case .internal(.content):
                break

            case .delegate:
                break
            }
            return .none
        }
    }
}

extension VideoPlayerFeature.State {
    func delayDismissOverlayIfNeeded() -> Effect<VideoPlayerFeature.Action> {
        if overlay == .tools {
            return .run { send in
                try await withTaskCancellation(id: Cancellables.delayCloseTab, cancelInFlight: true) {
                    try await Task.sleep(nanoseconds: 1_000_000_000 * 5)
                    await send(.internal(.hideToolsOverlay))
                }
            }
        } else {
            return .cancel(id: Cancellables.delayCloseTab)
        }
    }
}

public extension VideoPlayerFeature.State {
    func dismiss() -> Effect<VideoPlayerFeature.Action> {
        @Dependency(\.playerClient)
        var playerClient

        @Dependency(\.dismiss)
        var dismiss

        return .merge(
            .merge(Cancellables.allCases.map { .cancel(id: $0) }),
            .run { _ in
                await playerClient.clear()
                await dismiss()
            }
        )
    }

    mutating func clearForNewPlaylistIfNeeded(
        repoModuleID: RepoModuleID,
        playlist: Playlist,
        group: Playlist.Group,
        page: Playlist.Group.Content.Page,
        episodeId: Playlist.Item.ID
    ) -> Effect<VideoPlayerFeature.Action> {
        @Dependency(\.playerClient)
        var playerClient

        var shouldClearContents = false
        var shouldClearSources = false

        if repoModuleID != self.repoModuleID {
            self.repoModuleID = repoModuleID
            shouldClearSources = true
            shouldClearContents = true
        }

        if playlist.id != self.playlist.id {
            self.playlist = playlist
            shouldClearSources = true
            shouldClearContents = true
        }

        if group != selected.group {
            selected.group = group
            shouldClearSources = true
        }

        if page != selected.page {
            selected.page = page
            shouldClearSources = true
        }

        if episodeId != selected.episodeId {
            selected.episodeId = episodeId
            shouldClearSources = true
        }

        if shouldClearSources {
            selected.serverId = nil
            selected.linkId = nil
            selected.sourceId = nil

            loadables.serverResponseLoadables.removeAll()
            loadables.playlistItemSourcesLoadables.removeAll()

            return .merge(
                shouldClearContents ? loadables.contents.clear() : .none,
                loadables.contents.fetchPlaylistContentIfNecessary(repoModuleID, playlist.id),
                .run { await playerClient.clear() }
            )
        }

        return .none
    }

    fileprivate mutating func clearForNewEpisodeIfNeeded(
        _ group: Playlist.Group,
        _ page: Playlist.Group.Content.Page,
        _ episodeId: Playlist.Item.ID
    ) -> Effect<VideoPlayerFeature.Action> {
        @Dependency(\.playerClient)
        var playerClient

        if selected.group != group || selected.page != page || selected.episodeId != episodeId {
            selected.group = group
            selected.page = page
            selected.episodeId = episodeId
            selected.sourceId = nil
            selected.serverId = nil
            selected.linkId = nil
            loadables.serverResponseLoadables.removeAll()
            loadables.playlistItemSourcesLoadables.removeAll()
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

            if let sources = loadables[episodeId: selected.episodeId].value {
                selected.serverId = sources.first { $0.id == sourceId }?.servers.first?.id
            } else {
                selected.serverId = nil
            }
            selected.linkId = nil
            loadables.serverResponseLoadables.removeAll()

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

        if serverId != selected.serverId {
            selected.serverId = serverId
            selected.linkId = nil
            selected.serverId.flatMap { loadables.serverResponseLoadables[$0] = nil }

            return .merge(
                fetchServerIfNecessary(),
                .run {
                    await playerClient.clear()
                }
            )
        }

        return .none
    }

    mutating func clearForChangedLinkIfNeeded(_ linkId: Playlist.EpisodeServer.Link.ID) -> Effect<VideoPlayerFeature.Action> {
        @Dependency(\.playerClient)
        var playerClient

        if selected.linkId != linkId {
            selected.linkId = linkId

            if let server = selected.serverId.flatMap({ loadables[serverId: $0] })?.value,
               let link = server.links[id: linkId] {
                let playlist = playlist
                let episode = selectedItem.value.flatMap { $0 }
                let loadItem = PlayerClient.VideoCompositionItem(
                    link: link.url,
                    headers: server.headers,
                    subtitles: server.subtitles.map { subtitle in
                        .init(
                            name: subtitle.name,
                            default: subtitle.default,
                            autoselect: subtitle.autoselect,
                            forced: false,
                            link: subtitle.url
                        )
                    },
                    metadata: .init(
                        title: episode.flatMap { $0.title ?? "Episode \($0.number.withoutTrailingZeroes)" },
                        artworkImage: episode?.thumbnail ?? playlist.posterImage,
                        author: playlist.title
                    )
                )

                return .run { _ in
                    await playerClient.clear()
                    try await playerClient.load(loadItem)
                    await playerClient.play()
                }
            } else {
                return .run {
                    await playerClient.clear()
                }
            }
        }
        return .none
    }

    mutating func fetchSourcesIfNecessary(forced: Bool = false) -> Effect<VideoPlayerFeature.Action> {
        @Dependency(\.moduleClient)
        var moduleClient

        let repoModuleId = repoModuleID
        let playlist = playlist
        let episodeId = selected.episodeId

        if forced || !loadables[episodeId: episodeId].hasInitialized {
            loadables.update(with: episodeId, response: .loading)
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

        if forced || !loadables[serverId: serverId].hasInitialized {
            loadables.update(with: serverId, response: .loading)
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

                    await send(.internal(.serverResponse(serverId: serverId, .loaded(value))))
                }
            } catch: { error, send in
                await send(.internal(.serverResponse(serverId: serverId, .failed(error))))
            }
        }

        return .none
    }
}
