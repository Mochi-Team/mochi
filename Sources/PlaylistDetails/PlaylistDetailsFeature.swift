//
//  PlaylistDetailsFeature.swift
//
//
//  Created ErrorErrorError on 5/19/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
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
        public var contents: Loadable<PlaylistContents>

        var playlistInfo: Loadable<PlaylistInfo> {
            details.map { .init(playlist: playlist, details: $0) }
        }

        public init(
            repoModuleID: RepoModuleID,
            playlist: Playlist,
            details: Loadable<Playlist.Details> = .pending,
            contents: Loadable<PlaylistContents> = .pending
        ) {
            self.repoModuleId = repoModuleID
            self.playlist = playlist
            self.details = details
            self.contents = contents
        }

        @dynamicMemberLookup
        struct PlaylistInfo: Equatable, Sendable {
            let playlist: Playlist
            let details: Playlist.Details

            init(
                playlist: Playlist = .init(id: "", type: .video),
                details: Playlist.Details = .init()
            ) {
                self.playlist = playlist
                self.details = details
            }

            subscript<Value>(dynamicMember dynamicMember: KeyPath<Playlist, Value>) -> Value {
                playlist[keyPath: dynamicMember]
            }

            subscript<Value>(dynamicMember dynamicMember: KeyPath<Playlist.Details, Value>) -> Value {
                details[keyPath: dynamicMember]
            }
        }
    }

    public enum Action: FeatureAction {
        public enum ViewAction: SendableAction, BindableAction {
            case didAppear
            case didTappedBackButton
            case didTapSelectGroup(Playlist.Group.ID)
            case didTapVideoItem(Playlist.Group.ID, Playlist.Item.ID)
            case binding(BindingAction<State>)
        }

        public enum DelegateAction: SendableAction {
            case playbackVideoItem(
                Playlist.ItemsResponse,
                repoModuleID: RepoModuleID,
                playlist: Playlist,
                groupId: Playlist.Group.ID,
                itemId: Playlist.Item.ID
            )
        }

        public enum InternalAction: SendableAction {
            case playlistDetailsResponse(Loadable<Playlist.Details>)
            case playlistItemsResponse(Loadable<Playlist.ItemsResponse>)
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
