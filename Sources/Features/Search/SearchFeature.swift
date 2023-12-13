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
import Tagged
import ViewComponents

public struct SearchFeature: Feature {
    public struct State: FeatureState {
        @BindingState
        public var query: String
        @BindingState
        public var selectedFilters: [SearchFilter]

        public var repoModuleId: RepoModuleID?
        public var allFilters: [SearchFilter]
        public var items: Loadable<OrderedDictionary<PagingID, Loadable<Paging<Playlist>>>>

        public init(
            repoModuleId: RepoModuleID? = nil,
            query: String = "",
            selectedFilters: [SearchFilter] = [],
            allFilters: [SearchFilter] = [],
            items: Loadable<OrderedDictionary<PagingID, Loadable<Paging<Playlist>>>> = .pending
        ) {
            self.repoModuleId = repoModuleId
            self.query = query
            self.selectedFilters = selectedFilters
            self.allFilters = allFilters
            self.items = items
        }
    }

    @CasePathable
    public enum Action: FeatureAction {
        @CasePathable
        public enum ViewAction: SendableAction, BindableAction {
            case didAppear
            case didTapClearQuery
            case didTapClearFilters
            case didTapBackButton
            case didTapFilter(SearchFilter, SearchFilter.Option)
            case didTapPlaylist(Playlist)
            case didShowNextPageIndicator(PagingID)
            case binding(BindingAction<State>)
        }

        @CasePathable
        public enum DelegateAction: SendableAction {
            case playlistTapped(RepoModuleID, Playlist)
        }

        @CasePathable
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

        @SwiftUI.State
        var showStatusBarBackground = false

        @Environment(\.theme)
        var theme

        @MainActor
        public init(store: StoreOf<SearchFeature>) {
            self.store = store
        }
    }

    @Dependency(\.dismiss)
    var dismiss

    @Dependency(\.moduleClient)
    var moduleClient

    @Dependency(\.repoClient)
    var repoClient

    public init() {}
}
