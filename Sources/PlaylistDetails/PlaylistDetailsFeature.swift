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
import ModuleClient
import RepoClient
import SharedModels
import SwiftUI
import ViewComponents

public enum PlaylistDetailsFeature: Feature {
    public struct State: FeatureState {
        public let repoModuleId: RepoModuleID
        public let playlist: Playlist
        public var details: Loadable<Playlist.Details, ModuleClient.Error>
        public var contents: Loadable<PlaylistContents, ModuleClient.Error>

        var playlistInfo: Loadable<PlaylistInfo, ModuleClient.Error> {
            details.mapValue { .init(playlist: playlist, details: $0) }
        }

        public init(
            repoModuleID: RepoModuleID,
            playlist: Playlist,
            details: Loadable<Playlist.Details, ModuleClient.Error> = .pending,
            contents: Loadable<PlaylistContents, ModuleClient.Error> = .pending
        ) {
            self.repoModuleId = repoModuleID
            self.playlist = playlist
            self.details = details
            self.contents = contents
        }

        public struct RepoModuleID: Equatable, Sendable, Hashable {
            public let repoId: Repo.ID
            public let moduleId: Module.ID

            public init(
                repoId: Repo.ID,
                moduleId: Module.ID
            ) {
                self.repoId = repoId
                self.moduleId = moduleId
            }
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
            case didDissapear
            case binding(BindingAction<State>)
        }

        public enum DelegateAction: SendableAction {}

        public enum InternalAction: SendableAction {
            case playlistDetailsResponse(Loadable<Playlist.Details, ModuleClient.Error>)
            case playlistItemsResponse(Loadable<Playlist.ItemsResponse, ModuleClient.Error>)
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

        nonisolated public init(store: FeatureStoreOf<PlaylistDetailsFeature>) {
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

        public init() {}
    }
}
