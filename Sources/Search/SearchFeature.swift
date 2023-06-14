//
//  SearchFeature.swift
//
//
//  Created ErrorErrorError on 4/18/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import ModuleClient
import ModuleLists
import PlaylistDetails
import RepoClient
import SharedModels
import Styling
import SwiftUI
import ViewComponents

public enum SearchFeature: Feature {
    public struct Screens: ComposableArchitecture.Reducer {
        public init() {}

        public enum State: Equatable, Sendable {
            case playlistDetails(PlaylistDetailsFeature.State)
        }

        public enum Action: Equatable, Sendable {
            case playlistDetails(PlaylistDetailsFeature.Action)
        }

        public var body: some ComposableArchitecture.Reducer<State, Action> {
            Scope(state: /State.playlistDetails, action: /Action.playlistDetails) {
                PlaylistDetailsFeature.Reducer()
            }
        }
    }

    public struct State: FeatureState {
        @BindingState
        public var searchQuery: SearchQuery
        public var searchFilters: [SearchFilter]
        public var selectedModule: RepoClient.SelectedModule?
        public var items: Loadable<Paging<Playlist>>
        public var screens: StackState<Screens.State>

        @PresentationState
        public var moduleLists: ModuleListsFeature.State?

        var hasLoaded = false

        public init(
            searchQuery: SearchQuery = .init(query: ""),
            searchFilters: [SearchFilter] = [],
            selectedModule: RepoClient.SelectedModule? = nil,
            items: Loadable<Paging<Playlist>> = .pending,
            screens: StackState<Screens.State> = .init()
        ) {
            self.searchQuery = searchQuery
            self.searchFilters = searchFilters
            self.selectedModule = selectedModule
            self.items = items
            self.screens = screens
        }
    }

    public enum Action: FeatureAction {
        public enum ViewAction: SendableAction, BindableAction {
            case didAppear
            case didClearQuery
            case didTapOpenModules
            case didTapFilterOptions
            case didTapPlaylist(Playlist)
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
            case loadedSelectedModule(RepoClient.SelectedModule?)
            case loadedSearchFilters(TaskResult<[SearchFilter]>)
            case loadedItems(TaskResult<Paging<Playlist>>)
            case screens(StackAction<Screens.State, Screens.Action>)
            case moduleLists(PresentationAction<ModuleListsFeature.Action>)
        }

        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)
    }

    @MainActor
    public struct View: FeatureView {
        public let store: FeatureStoreOf<SearchFeature>

        @InsetValue(\.tabNavigation)
        var bottomNavInsetSize

        public nonisolated init(store: FeatureStoreOf<SearchFeature>) {
            self.store = store
        }
    }

    public struct Reducer: FeatureReducer {
        public typealias State = SearchFeature.State
        public typealias Action = SearchFeature.Action

        @Dependency(\.moduleClient)
        var moduleClient

        @Dependency(\.repoClient)
        var repoClient

        public init() {}
    }
}
