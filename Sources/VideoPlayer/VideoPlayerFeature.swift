//
//  VideoPlayerFeature.swift
//
//
//  Created ErrorErrorError on 5/26/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import ContentFetchingLogic
import LoggerClient
import ModuleClient
import PlayerClient
import SharedModels
import SwiftUI
import Tagged

// MARK: - VideoPlayerFeature

public enum VideoPlayerFeature: Feature {
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
                        return Image(systemName: "rectangle.stack.badge.play")
                    case .sourcesAndServers:
                        return Image(systemName: "server.rack")
                    case .qualityAndSubtitles:
                        return Image(systemName: "captions.bubble")
                    case .speed:
                        return Image(systemName: "speedometer")
                    case .settings:
                        return Image(systemName: "gearshape")
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

        public enum InternalAction: SendableAction {
            case hideToolsOverlay
            case sourcesResponse(episodeId: Playlist.Item.ID, _ response: Loadable<[Playlist.EpisodeSource]>)
            case serverResponse(serverId: Playlist.EpisodeServer.ID, _ response: Loadable<Playlist.EpisodeServerResponse>)
            case player(PlayerFeature.Action)
            case content(ContentFetchingLogic.Action)
        }

        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)
    }

    @MainActor
    public struct View: FeatureView {
        public let store: FeatureStoreOf<VideoPlayerFeature>

        public nonisolated init(store: FeatureStoreOf<VideoPlayerFeature>) {
            self.store = store
        }
    }

    public struct Reducer: FeatureReducer {
        public typealias State = VideoPlayerFeature.State
        public typealias Action = VideoPlayerFeature.Action

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
}

// TODO: Set not found as error

public extension VideoPlayerFeature.State {
    var selectedGroup: Loadable<ContentFetchingLogic.Pages> {
        loadables.contents.flatMap { groups in
            groups[selected.group] ?? .failed(ModuleClient.Error.unknown())
        }
    }

    var selectedPage: Loadable<Paging<Playlist.Item>> {
        selectedGroup.flatMap { pages in
            pages[selected.page] ?? .failed(ModuleClient.Error.unknown())
        }
    }

    var selectedItem: Loadable<Playlist.Item> {
        selectedPage.flatMap { page in
            page.items.first(where: \.id == selected.episodeId)
                .flatMap { .loaded($0) } ?? .failed(ModuleClient.Error.unknown())
        }
    }

    var selectedSource: Loadable<Playlist.EpisodeSource> {
        selectedItem.flatMap { item in
            loadables[episodeId: item.id].flatMap { sources in
                selected.sourceId.flatMap { sourceId in
                    sources[id: sourceId]
                }
                .flatMap { .loaded($0) } ?? .failed(ModuleClient.Error.unknown())
            }
        }
    }

    var selectedServer: Loadable<Playlist.EpisodeServer> {
        selectedSource.flatMap { source in
            selected.serverId.flatMap { serverId in
                source.servers[id: serverId]
            }
            .flatMap { .loaded($0) } ?? .failed(ModuleClient.Error.unknown())
        }
    }

    var selectedServerResponse: Loadable<Playlist.EpisodeServerResponse> {
        selectedServer.flatMap { server in
            loadables[serverId: server.id].flatMap { .loaded($0) }
        }
    }

    var selectedLink: Loadable<Playlist.EpisodeServer.Link> {
        selectedServerResponse.flatMap { serverResponse in
            selected.linkId.flatMap { linkId in serverResponse.links[id: linkId] }.flatMap { .loaded($0) } ?? .failed(ModuleClient.Error.unknown())
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
        public var contents = ContentFetchingLogic.State.pending
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
            contents: ContentFetchingLogic.State = .pending,
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
