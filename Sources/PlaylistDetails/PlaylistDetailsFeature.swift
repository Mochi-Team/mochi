//
//  PlaylistDetailsFeature.swift
//
//
//  Created ErrorErrorError on 5/19/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import ContentFetchingLogic
import DatabaseClient
import LoggerClient
import ModuleClient
import RepoClient
import SharedModels
import SwiftUI
import ViewComponents

public enum PlaylistDetailsFeature: Feature {
    public struct State: FeatureState {
        public let repoModuleId: RepoModuleID
        public let playlist: Playlist
        public var details: Loadable<Playlist.Details>
        public var content: ContentFetchingLogic.State

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
            content: ContentFetchingLogic.State = .pending
        ) {
            self.repoModuleId = repoModuleID
            self.playlist = playlist
            self.details = details
            self.content = content
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

        public enum InternalAction: SendableAction {
            case playlistDetailsResponse(Loadable<Playlist.Details>)
            case content(ContentFetchingLogic.Action)
        }

        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)
    }

    @MainActor
    public struct View: FeatureView {
        public let store: FeatureStoreOf<PlaylistDetailsFeature>

        @InsetValue(\.tabNavigation)
        var tabNavigationInset

        @SwiftUI.State
        var imageDominatColor: Color?

        public nonisolated init(store: FeatureStoreOf<PlaylistDetailsFeature>) {
            self.store = store
        }
    }

    public struct Reducer: FeatureReducer {
        public typealias State = PlaylistDetailsFeature.State
        public typealias Action = PlaylistDetailsFeature.Action

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
}
