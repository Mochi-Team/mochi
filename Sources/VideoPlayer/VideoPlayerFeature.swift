//
//  VideoPlayerFeature.swift
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
            groupId: Playlist.Group.ID,
            episodeId: Playlist.Item.ID,
            overlay: Overlay? = .tools,
            player: PlayerFeature.State = .init()
        ) {
            self.repoModuleID = repoModuleID
            self.playlist = playlist
            self.loadables = contents
            self.selected = .init(
                groupId: groupId,
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
            case didTapPlayEpisode(Playlist.Group.ID, Playlist.Item.ID)
            case didTapSource(Playlist.EpisodeSource.ID)
            case didTapServer(Playlist.EpisodeServer.ID)
            case didTapLink(Playlist.EpisodeServer.Link.ID)
        }

        public enum DelegateAction: SendableAction {}

        public enum InternalAction: SendableAction {
            case hideToolsOverlay
            case groupResponse(groupId: Playlist.Group.ID, _ response: Loadable<Playlist.ItemsResponse>)
            case sourcesResponse(episodeId: Playlist.Item.ID, _ response: Loadable<[Playlist.EpisodeSource]>)
            case serverResponse(serverId: Playlist.EpisodeServer.ID, _ response: Loadable<Playlist.EpisodeServerResponse>)
            case player(PlayerFeature.Action)
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

public extension VideoPlayerFeature.State {
    var selectedGroup: Loadable<Playlist.Group.Content> {
        loadables[groupId: selected.groupId]
    }

    var selectedEpisode: Loadable<Playlist.Item?> {
        selectedGroup.map { $0.items[id: selected.episodeId] }
    }

    var selectedSource: Loadable<Playlist.EpisodeSource?> {
        selectedEpisode.flatMap { item in
            if let item {
                return loadables[episodeId: item.id].map { sources in
                    selected.sourceId.flatMap { sourceId in
                        sources[id: sourceId]
                    }
                }
            }
            return .loaded(nil)
        }
    }

    var selectedServer: Loadable<Playlist.EpisodeServer?> {
        selectedSource.map { source in
            if let source {
                return selected.serverId.flatMap { serverId in
                    source.servers[id: serverId]
                }
            }
            return nil
        }
    }

    var selectedServerResponse: Loadable<Playlist.EpisodeServerResponse?> {
        selectedServer.flatMap { server in
            if let server {
                return loadables[serverId: server.id].flatMap { .loaded($0) }
            }
            return .loaded(nil)
        }
    }

    var selectedLink: Loadable<Playlist.EpisodeServer.Link?> {
        selectedServerResponse.map { serverResponse in
            if let serverResponse {
                return selected.linkId.flatMap { linkId in
                    serverResponse.links[id: linkId]
                }
            }
            return nil
        }
    }

    struct SelectedContent: Equatable, Sendable {
        public var groupId: Playlist.Group.ID
        public var episodeId: Playlist.Item.ID
        public var sourceId: Playlist.EpisodeSource.ID?
        public var serverId: Playlist.EpisodeServer.ID?
        public var linkId: Playlist.EpisodeServer.Link.ID?

        public init(
            groupId: Playlist.Group.ID,
            episodeId: Playlist.Item.ID,
            sourceId: Playlist.EpisodeSource.ID? = nil,
            serverId: Playlist.EpisodeServer.ID? = nil,
            linkId: Playlist.EpisodeServer.Link.ID? = nil
        ) {
            self.groupId = groupId
            self.episodeId = episodeId
            self.sourceId = sourceId
            self.serverId = serverId
            self.linkId = linkId
        }
    }

    struct Loadables: Equatable, Sendable {
        public var allGroupsLoadable = Loadable<[Playlist.Group]>.pending
        public var groupContentLoadables = [Playlist.Group.ID: Loadable<Playlist.Group.Content>]()
        public var playlistItemSourcesLoadables = [Playlist.Item.ID: Loadable<[Playlist.EpisodeSource]>]()
        public var serverResponseLoadables = [Playlist.EpisodeServer.ID: Loadable<Playlist.EpisodeServerResponse>]()

        subscript(groupId groupId: Playlist.Group.ID) -> Loadable<Playlist.Group.Content> {
            get { groupContentLoadables[groupId] ?? .pending }
            set { groupContentLoadables[groupId] = newValue }
        }

        subscript(episodeId episodeId: Playlist.Item.ID) -> Loadable<[Playlist.EpisodeSource]> {
            get { playlistItemSourcesLoadables[episodeId] ?? .pending }
            set { playlistItemSourcesLoadables[episodeId] = newValue }
        }

        subscript(serverId serverId: Playlist.EpisodeServer.ID) -> Loadable<Playlist.EpisodeServerResponse> {
            get { serverResponseLoadables[serverId] ?? .pending }
            set { serverResponseLoadables[serverId] = newValue }
        }

        public init(
            allGroupsLoadable: Loadable<[Playlist.Group]> = .pending,
            groupContentLoadables: [Playlist.Group.ID: Loadable<Playlist.Group.Content>] = [:],
            playlistItemSourcesLoadables: [Playlist.Item.ID: Loadable<[Playlist.EpisodeSource]>] = [:],
            serverResponseLoadables: [Playlist.EpisodeServer.ID: Loadable<Playlist.EpisodeServerResponse>] = [:]
        ) {
            self.allGroupsLoadable = allGroupsLoadable
            self.groupContentLoadables = groupContentLoadables
            self.playlistItemSourcesLoadables = playlistItemSourcesLoadables
            self.serverResponseLoadables = serverResponseLoadables
        }

        public mutating func update(
            with groupId: Playlist.Group.ID,
            response: Loadable<Playlist.ItemsResponse>
        ) {
            groupContentLoadables[groupId] = response.map(\.content)

            if groupContentLoadables.allSatisfy({ $1.error != nil }) {
                allGroupsLoadable = .failed(ModuleClient.Error.unknown())
            } else {
                switch (allGroupsLoadable, response) {
                case let (_, .loaded(value)):
                    allGroupsLoadable = .loaded(value.allGroups)
                default:
                    break
                }
            }
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
