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
import OrderedCollections
import PlaylistDetails
import RepoClient
import SharedModels
import Styling
import SwiftUI
import ViewComponents

public struct SearchFeature: Feature {
    public struct Screens: Reducer {
        public init() {}

        public enum State: Equatable, Sendable {
            case playlistDetails(PlaylistDetailsFeature.State)
        }

        public enum Action: Equatable, Sendable {
            case playlistDetails(PlaylistDetailsFeature.Action)
        }

        public var body: some ReducerOf<Self> {
            Scope(state: /State.playlistDetails, action: /Action.playlistDetails) {
                PlaylistDetailsFeature()
            }
        }
    }

    public struct State: FeatureState {
        @BindingState
        public var searchQuery: String
        public var searchFilters: [SearchFilter]
        public var selectedModule: RepoClient.SelectedModule?
        public var items: Loadable<OrderedDictionary<PagingID, Loadable<Paging<Playlist>>>>
        public var screens: StackState<Screens.State>

        @PresentationState
        public var moduleLists: ModuleListsFeature.State?

        var hasLoaded = false

        public init(
            searchQuery: String = "",
            searchFilters: [SearchFilter] = [],
            selectedModule: RepoClient.SelectedModule? = nil,
            items: Loadable<OrderedDictionary<PagingID, Loadable<Paging<Playlist>>>> = .pending,
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
            case didShowNextPageIndicator(PagingID)
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
            case loadedSelectedModule(RepoClient.SelectedModule?)
            case loadedSearchFilters(TaskResult<[SearchFilter]>)
            case loadedItems(Loadable<Paging<Playlist>>)
            case loadedPageResult(PagingID, Loadable<Paging<Playlist>>)
            case screens(StackAction<Screens.State, Screens.Action>)
            case moduleLists(PresentationAction<ModuleListsFeature.Action>)
        }

        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)
    }

    @MainActor
    public struct View: FeatureView {
        public let store: StoreOf<SearchFeature>

//        @InsetValue(\.bottomNavigation)
//        var bottomNavigationSize

        public nonisolated init(store: StoreOf<SearchFeature>) {
            self.store = store
        }
    }

    @Dependency(\.moduleClient)
    var moduleClient

    @Dependency(\.repoClient)
    var repoClient

    @Dependency(\.logger)
    var logger

    public init() {}
}
