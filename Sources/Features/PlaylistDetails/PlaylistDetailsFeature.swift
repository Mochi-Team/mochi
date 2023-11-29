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
        public var content: ContentCore.State
        public var playlist: Playlist { content.playlist }
        public var details: Loadable<Playlist.Details>

        @PresentationState
        public var destination: Destination.State?

        var playlistInfo: Loadable<PlaylistInfo> {
            details.map { .init(playlist: playlist, details: $0) }
        }

        public var resumableState: Resumable {
            content.groups.didFinish ? (content.groups.value == nil ? .unavailable : .start) : .loading
        }

        public init(
            content: ContentCore.State,
            details: Loadable<Playlist.Details> = .pending,
            destination: Destination.State? = nil
        ) {
            self.content = content
            self.details = details
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
                    "Loading..."
                case .start:
                    "Start"
                case .continue:
                    "Continue"
                case .unavailable:
                    "Unavailable"
                }
            }
        }
    }

    @CasePathable
    public enum Action: FeatureAction {
        @CasePathable
        public enum ViewAction: SendableAction, BindableAction {
            case onTask
            case didTappedBackButton
            case didTapToRetryDetails
            case didTapOnReadMore
            case binding(BindingAction<State>)
        }

        @CasePathable
        public enum DelegateAction: SendableAction {
            case playbackVideoItem(
                Playlist.ItemsResponse,
                repoModuleId: RepoModuleID,
                playlist: Playlist,
                group: Playlist.Group.ID,
                variant: Playlist.Group.Variant.ID,
                paging: PagingID,
                itemId: Playlist.Item.ID
            )
        }

        @CasePathable
        public enum InternalAction: SendableAction {
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

        @SwiftUI.State
        var imageDominatColor: Color?

        @Environment(\.theme)
        var theme

        @MainActor
        public init(store: StoreOf<PlaylistDetailsFeature>) {
            self.store = store
        }
    }

    @Dependency(\.moduleClient)
    var moduleClient

    @Dependency(\.databaseClient)
    var databaseClient

    @Dependency(\.repoClient)
    var repoClient

    @Dependency(\.dismiss)
    var dismiss

    public init() {}
}
