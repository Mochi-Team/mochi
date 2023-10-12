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
    public struct State: FeatureState {
        @BindingState public var expandView: Bool
        @BindingState public var searchFieldFocused: Bool
        @BindingState public var query: String

        public var repoModuleID: RepoModuleID?
        public var filters: [SearchFilter]
        public var items: Loadable<OrderedDictionary<PagingID, Loadable<Paging<Playlist>>>>

        public init(
            expandView: Bool = false,
            searchFieldFocused: Bool = false,
            repoModuleID: RepoModuleID? = nil,
            query: String = "",
            filters: [SearchFilter] = [],
            items: Loadable<OrderedDictionary<PagingID, Loadable<Paging<Playlist>>>> = .pending
        ) {
            self.repoModuleID = repoModuleID
            self.expandView = expandView
            self.searchFieldFocused = searchFieldFocused
            self.query = query
            self.filters = filters
            self.items = items
        }
    }

    public enum Action: FeatureAction {
        public enum ViewAction: SendableAction, BindableAction {
            case didAppear
            case didTapClearQuery
            case didTapFilterOptions
            case didTapPlaylist(Playlist)
            case didShowNextPageIndicator(PagingID)
            case binding(BindingAction<State>)
        }

        public enum DelegateAction: SendableAction {
            case playlistTapped(RepoModuleID, Playlist)
        }

        public enum InternalAction: SendableAction {
            case loadedSearchFilters(TaskResult<[SearchFilter]>)
            case loadedItems(Loadable<Paging<Playlist>>)
            case loadedPageResult(PagingID, Loadable<Paging<Playlist>>)
        }

        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)
    }

    @MainActor
    public struct View: FeatureView {
        public let store: StoreOf<SearchFeature>

        var onSearchBarSizeChanged: (CGSize) -> Void = { _ in }

        @SwiftUI.State
        var searchBarSize = 0.0

        @FocusState
        var searchFieldFocused: Bool

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
