//
//  VideoPlayerFeature.swift
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
import SwiftUI
import Tagged

// MARK: - VideoPlayerFeature

public struct VideoPlayerFeature: Feature {
    public enum Error: Swift.Error {
        case contentNotFound
    }

    public struct State: FeatureState {
        public enum Overlay: Sendable, Equatable {
            case tools
            case more(MoreTab)

            public enum MoreTab: String, Sendable, Equatable, CaseIterable {
                case episodes = "Episodes"
                case sourcesAndServers = "Sources & Servers"
                case qualityAndSubtitles = "Quality & Subtitles"
                case speed = "Playback Speed"
                case settings = "Settings"

                var image: Image {
                    switch self {
                    case .episodes:
                        Image(systemName: "rectangle.stack.badge.play")
                    case .sourcesAndServers:
                        Image(systemName: "server.rack")
                    case .qualityAndSubtitles:
                        Image(systemName: "captions.bubble")
                    case .speed:
                        Image(systemName: "speedometer")
                    case .settings:
                        Image(systemName: "gearshape")
                    }
                }
            }
        }

        public var repoModuleID: RepoModuleID
        public var playlist: Playlist
        public var loadables: Loadables
        public var selected: SelectedContent
        public var overlay: Overlay?
        public var player: PlayerFeature.State

        public init(
            repoModuleID: RepoModuleID,
            playlist: Playlist,
            loadables: Loadables = .init(),
            selected: SelectedContent,
            overlay: Overlay? = .tools,
            player: PlayerFeature.State = .init()
        ) {
            self.repoModuleID = repoModuleID
            self.playlist = playlist
            self.loadables = loadables
            self.selected = selected
            self.overlay = overlay
            self.player = player
        }

        public init(
            repoModuleID: RepoModuleID,
            playlist: Playlist,
            contents: Loadables = .init(),
            group: Playlist.Group,
            page: Playlist.Group.Content.Page,
            episodeId: Playlist.Item.ID,
            overlay: Overlay? = .tools,
            player: PlayerFeature.State = .init()
        ) {
            self.repoModuleID = repoModuleID
            self.playlist = playlist
            self.loadables = contents
            self.selected = .init(
                group: group,
                page: page,
                episodeId: episodeId
            )
            self.overlay = overlay
            self.player = player
        }
    }

    public enum Action: FeatureAction {
        public enum ViewAction: SendableAction {
            case didAppear
            case didTapBackButton
            case didTapMoreButton
            case didTapPlayer
            case didSelectMoreTab(State.Overlay.MoreTab)
            case didTapCloseMoreOverlay
            case didSkipTo(time: CGFloat)
            case didTapContentGroup(Playlist.Group)
            case didTapContentGroupPage(Playlist.Group, Playlist.Group.Content.Page)
            case didTapPlayEpisode(Playlist.Group, Playlist.Group.Content.Page, Playlist.Item.ID)
            case didTapSource(Playlist.EpisodeSource.ID)
            case didTapServer(Playlist.EpisodeServer.ID)
            case didTapLink(Playlist.EpisodeServer.Link.ID)
        }

        public enum DelegateAction: SendableAction {}

        public enum InternalAction: SendableAction, ContentAction {
            case hideToolsOverlay
            case sourcesResponse(episodeId: Playlist.Item.ID, _ response: Loadable<[Playlist.EpisodeSource]>)
            case serverResponse(serverId: Playlist.EpisodeServer.ID, _ response: Loadable<Playlist.EpisodeServerResponse>)
            case player(PlayerFeature.Action)
            case content(ContentCore.Action)
        }

        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)
    }

    @MainActor
    public struct View: FeatureView {
        public let store: StoreOf<VideoPlayerFeature>

        public nonisolated init(store: StoreOf<VideoPlayerFeature>) {
            self.store = store
        }
    }

    @Dependency(\.dismiss)
    var dismiss

    @Dependency(\.moduleClient)
    var moduleClient

    @Dependency(\.logger)
    var logger

    @Dependency(\.playerClient)
    var playerClient

    public init() {}
}

public extension VideoPlayerFeature.State {
    var selectedGroup: Loadable<ContentCore.Pages> {
        loadables.contents.flatMap { groups in
            groups[selected.group] ?? .failed(VideoPlayerFeature.Error.contentNotFound)
        }
    }

    var selectedPage: Loadable<Paging<Playlist.Item>> {
        selectedGroup.flatMap { pages in
            pages[selected.page] ?? .failed(VideoPlayerFeature.Error.contentNotFound)
        }
    }

    var selectedItem: Loadable<Playlist.Item> {
        selectedPage.flatMap { page in
            page.items.first(where: \.id == selected.episodeId)
                .flatMap { .loaded($0) } ?? .failed(VideoPlayerFeature.Error.contentNotFound)
        }
    }

    var selectedSource: Loadable<Playlist.EpisodeSource> {
        selectedItem.flatMap { item in
            loadables[episodeId: item.id].flatMap { sources in
                selected.sourceId.flatMap { sourceId in
                    sources[id: sourceId]
                }
                .flatMap { .loaded($0) } ?? .failed(VideoPlayerFeature.Error.contentNotFound)
            }
        }
    }

    var selectedServer: Loadable<Playlist.EpisodeServer> {
        selectedSource.flatMap { source in
            selected.serverId.flatMap { serverId in
                source.servers[id: serverId]
            }
            .flatMap { .loaded($0) } ?? .failed(VideoPlayerFeature.Error.contentNotFound)
        }
    }

    var selectedServerResponse: Loadable<Playlist.EpisodeServerResponse> {
        selectedServer.flatMap { server in
            loadables[serverId: server.id].flatMap { .loaded($0) }
        }
    }

    var selectedLink: Loadable<Playlist.EpisodeServer.Link> {
        selectedServerResponse.flatMap { serverResponse in
            selected.linkId.flatMap { linkId in
                serverResponse.links[id: linkId]
            }
            .flatMap { .loaded($0) } ?? .failed(VideoPlayerFeature.Error.contentNotFound)
        }
    }

    struct SelectedContent: Equatable, Sendable {
        public var group: Playlist.Group
        public var page: Playlist.Group.Content.Page
        public var episodeId: Playlist.Item.ID
        public var sourceId: Playlist.EpisodeSource.ID?
        public var serverId: Playlist.EpisodeServer.ID?
        public var linkId: Playlist.EpisodeServer.Link.ID?

        public init(
            group: Playlist.Group,
            page: Playlist.Group.Content.Page,
            episodeId: Playlist.Item.ID,
            sourceId: Playlist.EpisodeSource.ID? = nil,
            serverId: Playlist.EpisodeServer.ID? = nil,
            linkId: Playlist.EpisodeServer.Link.ID? = nil
        ) {
            self.group = group
            self.page = page
            self.episodeId = episodeId
            self.sourceId = sourceId
            self.serverId = serverId
            self.linkId = linkId
        }
    }

    struct Loadables: Equatable, Sendable {
        public var contents = ContentCore.State.pending
        public var playlistItemSourcesLoadables = [Playlist.Item.ID: Loadable<[Playlist.EpisodeSource]>]()
        public var serverResponseLoadables = [Playlist.EpisodeServer.ID: Loadable<Playlist.EpisodeServerResponse>]()

        subscript(episodeId episodeId: Playlist.Item.ID) -> Loadable<[Playlist.EpisodeSource]> {
            get { playlistItemSourcesLoadables[episodeId] ?? .pending }
            set { playlistItemSourcesLoadables[episodeId] = newValue }
        }

        subscript(serverId serverId: Playlist.EpisodeServer.ID) -> Loadable<Playlist.EpisodeServerResponse> {
            get { serverResponseLoadables[serverId] ?? .pending }
            set { serverResponseLoadables[serverId] = newValue }
        }

        public init(
            contents: ContentCore.State = .pending,
            playlistItemSourcesLoadables: [Playlist.Item.ID: Loadable<[Playlist.EpisodeSource]>] = [:],
            serverResponseLoadables: [Playlist.EpisodeServer.ID: Loadable<Playlist.EpisodeServerResponse>] = [:]
        ) {
            self.contents = contents
            self.playlistItemSourcesLoadables = playlistItemSourcesLoadables
            self.serverResponseLoadables = serverResponseLoadables
        }

        public mutating func update(
            with episodeId: Playlist.Item.ID,
            response: Loadable<[Playlist.EpisodeSource]>
        ) {
            playlistItemSourcesLoadables[episodeId] = response
        }

        public mutating func update(
            with serverId: Playlist.EpisodeServer.ID,
            response: Loadable<Playlist.EpisodeServerResponse>
        ) {
            serverResponseLoadables[serverId] = response
        }
    }
}

extension VideoPlayerFeature.View {
    struct SkipActionViewState: Equatable {
        enum Action: Hashable, CustomStringConvertible {
            case times(Playlist.EpisodeServer.SkipTime)
            case next(Double, Playlist.Group, Playlist.Group.Content.Page, Playlist.Item.ID)

            var isEnding: Bool {
                if case let .times(time) = self {
                    return time.type == .ending
                }
                return false
            }

            var action: VideoPlayerFeature.Action {
                switch self {
                case let .next(_, group, paging, itemId):
                    .view(.didTapPlayEpisode(group, paging, itemId))
                case let .times(time):
                    .view(.didSkipTo(time: time.endTime))
                }
            }

            var description: String {
                switch self {
                case let .times(time):
                    time.type.description
                case let .next(number, _, _, _):
                    "Play E\(number.withoutTrailingZeroes)"
                }
            }

            var image: String {
                switch self {
                case .next:
                    "play.fill"
                default:
                    "forward.fill"
                }
            }

            var textColor: Color {
                if case .next = self {
                    return .black
                }
                return .white
            }

            var background: Color {
                if case .next = self {
                    return .white
                }
                return .init(white: 0.25)
            }
        }

        var actions: [Action]
        var canShowActions: Bool

        var visible: Bool {
            canShowActions && !actions.isEmpty
        }

        init(_ state: VideoPlayerFeature.State) {
            self.canShowActions = state.player.duration.isValid && state.player.duration > .zero
            self.actions = state.selectedServerResponse.value?.skipTimes
                .filter { $0.startTime <= state.player.progress.seconds && state.player.progress.seconds <= $0.endTime }
                .sorted(by: \.startTime)
                .compactMap { .times($0) } ?? []

            if let currentEpisode = state.selectedItem.value,
               let episodes = state.selectedPage.value?.items,
               let index = episodes.firstIndex(where: { $0.id == currentEpisode.id }), (index + 1) < episodes.endIndex {
                let nextEpisode = episodes[index + 1]

                if let ending = actions.first(where: \.isEnding), case let .times(type) = ending {
                    if state.player.progress.seconds >= type.startTime {
                        actions.append(.next(nextEpisode.number, state.selected.group, state.selected.page, nextEpisode.id))
                    }
                } else if state.player.progress.seconds >= (0.92 * state.player.duration.seconds) {
                    actions.append(.next(nextEpisode.number, state.selected.group, state.selected.page, nextEpisode.id))
                }
            }
        }
    }
}
