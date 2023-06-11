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
import SharedModels
import SwiftUI
import Tagged

public enum VideoPlayerFeature: Feature {
    public struct State: FeatureState {
        public enum Overlay: Sendable, Equatable {
            case tools
            case more(MoreTab)

            public enum MoreTab: String, Sendable, Equatable, CaseIterable {
                case episodes = "Episodes"
                case sourcesAndServers = "Sources and Servers"
                case speed = "Speed"
                case qualityAndSubtitles = "Quality and Subtitles"
                case settings = "Settings"
            }
        }

        public let repoModuleID: RepoModuleID
        public let playlist: Playlist
        public var contents: Contents
        public var selected: SelectedContent
        public var overlay: Overlay?
        public var player: PlayerReducer.State

        public init(
            repoModuleID: RepoModuleID,
            playlist: Playlist,
            contents: Contents,
            groupId: Playlist.Group.ID,
            episodeId: Playlist.Item.ID,
            overlay: Overlay? = .tools,
            player: PlayerReducer.State = .init()
        ) {
            self.repoModuleID = repoModuleID
            self.playlist = playlist
            self.contents = contents
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
            case didTapGoForwards
            case didTapGoBackwards
            case didStartedSeeking
            case didFinishedSeekingTo(CGFloat)
            case didTapCloseMoreOverlay
            case didTapPlayEpisode(Playlist.Group.ID, Playlist.Item.ID)
            case didTapSource(Playlist.EpisodeSource.ID)
            case didTapServer(Playlist.EpisodeServer.ID)
            case didTapLink(Playlist.EpisodeServer.Link.ID)
        }

        public enum DelegateAction: SendableAction {}

        public enum InternalAction: SendableAction {
            case groupResponse(groupId: Playlist.Group.ID, _ response: Loadable<Playlist.ItemsResponse>)
            case sourcesResponse(episodeId: Playlist.Item.ID, _ response: Loadable<[Playlist.EpisodeSource]>)
            case serverResponse(sourceId: Playlist.EpisodeSource.ID, _ response: Loadable<Playlist.EpisodeServerResponse>)
            case player(PlayerReducer.Action)
        }

        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)
    }

    @MainActor
    public struct View: FeatureView {
        public let store: FeatureStoreOf<VideoPlayerFeature>

        @Dependency(\.videoPlayerClient.player)
        var player

        @SwiftUI.Environment(\.horizontalSizeClass)
        var horizontalSizeClass

        nonisolated public init(store: FeatureStoreOf<VideoPlayerFeature>) {
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

        @Dependency(\.videoPlayerClient)
        var videoPlayerClient

        public init() {}
    }
}

extension VideoPlayerFeature.State {
    public struct SelectedContent: Equatable, Sendable {
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

    public struct Contents: Equatable, Sendable {
        public var allGroups = Loadable<[Playlist.Group]>.pending
        public var groups = [Playlist.Group.ID: Loadable<Playlist.Group.Content>]()
        public var sources = [Playlist.Item.ID: Loadable<[Playlist.EpisodeSource]>]()
        public var serverLinks = [Playlist.EpisodeSource.ID: Loadable<Playlist.EpisodeServerResponse>]()

        subscript(groupId groupId: Playlist.Group.ID) -> Loadable<Playlist.Group.Content> {
            get { groups[groupId] ?? .pending }
            set { groups[groupId] = newValue }
        }

        subscript(episodeId episodeId: Playlist.Item.ID) -> Loadable<[Playlist.EpisodeSource]> {
            get { sources[episodeId] ?? .pending }
            set { sources[episodeId] = newValue }
        }

        subscript(sourceId sourceId: Playlist.EpisodeSource.ID) -> Loadable<Playlist.EpisodeServerResponse> {
            get { serverLinks[sourceId] ?? .pending }
            set { serverLinks[sourceId] = newValue }
        }

        public init(
            allGroups: Loadable<[Playlist.Group]> = .pending,
            groups: [Playlist.Group.ID: Loadable<Playlist.Group.Content>] = [:],
            sources: [Playlist.Item.ID: Loadable<[Playlist.EpisodeSource]>] = [:],
            servers: [Playlist.EpisodeSource.ID: Loadable<Playlist.EpisodeServerResponse>] = [:]
        ) {
            self.allGroups = allGroups
            self.groups = groups
            self.sources = sources
            self.serverLinks = servers
        }

        public mutating func update(
            with groupId: Playlist.Group.ID,
            response: Loadable<Playlist.ItemsResponse>
        ) {
            groups[groupId] = response.map(\.content)

            if groups.allSatisfy({ $1.error != nil }) {
                allGroups = .failed(ModuleClient.Error.unknown())
            } else {
                switch (allGroups, response) {
                case let (_, .loaded(value)):
                    allGroups = .loaded(value.allGroups)
                default:
                    break
                }
            }
        }

        public mutating func update(
            with episodeId: Playlist.Item.ID,
            response: Loadable<[Playlist.EpisodeSource]>
        ) {
            sources[episodeId] = response
        }

        public mutating func update(
            with sourceId: Playlist.EpisodeSource.ID,
            response: Loadable<Playlist.EpisodeServerResponse>
        ) {
            serverLinks[sourceId] = response
        }

        public mutating func clearServers() {
            serverLinks.removeAll()
        }
    }
}
