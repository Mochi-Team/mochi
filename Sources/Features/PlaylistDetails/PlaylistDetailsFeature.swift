//
//  PlaylistDetailsFeature.swift
//
//
//  Created ErrorErrorError on 5/19/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import ContentCore
import DatabaseClient
import LoggerClient
import ModuleClient
import RepoClient
import SharedModels
import Styling
import SwiftUI
import ViewComponents

public struct PlaylistDetailsFeature: Feature {
    public struct Destination: ComposableArchitecture.Reducer {
        public enum State: Equatable, Sendable {
            case readMore(ReadMore.State)
        }

        public enum Action: Equatable, Sendable {
            case readMore(ReadMore.Action)
        }

        public var body: some ReducerOf<Self> {
            Scope(state: /State.readMore, action: /Action.readMore) {
                ReadMore()
            }
        }

        public struct ReadMore: ComposableArchitecture.Reducer {
            public struct State: Equatable, Sendable {
                public let title: String
                public let description: String

                public init(
                    title: String,
                    description: String
                ) {
                    self.title = title
                    self.description = description
                }
            }

            public enum Action: Equatable, Sendable {}

            public var body: some ReducerOf<Self> { EmptyReducer() }
        }
    }

    public struct State: FeatureState {
        public let repoModuleId: RepoModuleID
        public let playlist: Playlist
        public var details: Loadable<Playlist.Details>
        public var content: ContentCore.State

        @PresentationState
        public var destination: Destination.State?

        var playlistInfo: Loadable<PlaylistInfo> {
            details.map { .init(playlist: playlist, details: $0) }
        }

        public var resumableState: Resumable {
            content.didFinish ? (content.value == nil ? .unavailable : .start) : .loading
        }

        public init(
            repoModuleID: RepoModuleID,
            playlist: Playlist,
            details: Loadable<Playlist.Details> = .pending,
            content: ContentCore.State = .pending,
            destination: Destination.State? = nil
        ) {
            self.repoModuleId = repoModuleID
            self.playlist = playlist
            self.details = details
            self.content = content
            self.destination = destination
        }

        public enum Resumable: Equatable, Sendable {
            case loading
            case start
            case `continue`(String, Double)
            case unavailable

            var image: Image? {
                self != .unavailable ? .init(systemName: "play.fill") : nil
            }

            var description: String {
                switch self {
                case .loading:
                    return ""
                case .start:
                    return "Start"
                case .continue:
                    return "Continue"
                case .unavailable:
                    return "Unavailable"
                }
            }
        }
    }

    public enum Action: FeatureAction {
        public enum ViewAction: SendableAction, BindableAction {
            case didAppear
            case didTappedBackButton
            case didTapToRetryDetails
            case didTapOnReadMore
            case didTapContentGroup(Playlist.Group)
            case didTapContentGroupPage(Playlist.Group, Playlist.Group.Content.Page)
            case didTapVideoItem(Playlist.Group, Playlist.Group.Content.Page, Playlist.Item.ID)
            case binding(BindingAction<State>)
        }

        public enum DelegateAction: SendableAction {
            case playbackVideoItem(
                Playlist.ItemsResponse,
                repoModuleID: RepoModuleID,
                playlist: Playlist,
                group: Playlist.Group,
                paging: Playlist.Group.Content.Page,
                itemId: Playlist.Item.ID
            )
        }

        public enum InternalAction: SendableAction, ContentAction {
            case playlistDetailsResponse(Loadable<Playlist.Details>)
            case content(ContentCore.Action)
            case destination(PresentationAction<Destination.Action>)
        }

        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)
    }

    @MainActor
    public struct View: FeatureView {
        public let store: StoreOf<PlaylistDetailsFeature>

        @Environment(\.openURL)
        var openURL

        @InsetValue(\.bottomNavigation)
        var bottomNavigationSize

        @SwiftUI.State
        var imageDominatColor: Color?

        @EnvironmentObject var theme: ThemeManager

        public nonisolated init(store: StoreOf<PlaylistDetailsFeature>) {
            self.store = store
        }
    }

    @Dependency(\.moduleClient)
    var moduleClient

    @Dependency(\.databaseClient)
    var databaseClient

    @Dependency(\.repoClient)
    var repoClient

    @Dependency(\.logger)
    var logger

    @Dependency(\.dismiss)
    var dismiss

    public init() {}
}
