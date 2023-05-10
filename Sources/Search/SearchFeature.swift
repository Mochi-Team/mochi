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
import RepoClient
import SharedModels
import SwiftUI
import ViewComponents

public enum SearchFeature: Feature {
    public struct State: FeatureState {
        @BindingState
        public var searchQuery: SearchQuery
        public var searchFilters: [SearchFilter]
        public var selectedModule: RepoClient.SelectedModule?
        public var items: Loadable<Paging<Media>, ModuleClient.Error>

        var hasLoaded = false

        public init(
            searchQuery: SearchQuery = .init(query: ""),
            searchFilters: [SearchFilter] = [],
            selectedModule: RepoClient.SelectedModule? = nil,
            items: Loadable<Paging<Media>, ModuleClient.Error> = .pending
        ) {
            self.searchQuery = searchQuery
            self.searchFilters = searchFilters
            self.selectedModule = selectedModule
            self.items = items
        }
    }

    public enum Action: FeatureAction {
        public enum ViewAction: SendableAction, BindableAction {
            case didAppear
            case didClearQuery
            case didTapOpenModules
            case didTapFilterOptions
            case binding(BindingAction<State>)
        }

        public enum DelegateAction: SendableAction {
            case tappedOpenModules
        }

        public enum InternalAction: SendableAction {
            case loadedSelectedModule(RepoClient.SelectedModule?)
            case loadedSearchFilters(TaskResult<[SearchFilter]>)
            case loadedItems(TaskResult<Paging<Media>>)
        }

        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)
    }

    @MainActor
    public struct View: FeatureView {
        public let store: FeatureStoreOf<SearchFeature>

        @InsetValue(\.tabNavigation)
        var tabNavInsetSize

        @SwiftUI.State
        var topBarSize = SizeInset.zero

        nonisolated public init(store: FeatureStoreOf<SearchFeature>) {
            self.store = store
        }
    }

    public struct Reducer: FeatureReducer {
        public typealias State = SearchFeature.State
        public typealias Action = SearchFeature.Action

        @Dependency(\.moduleClient)
        var moduleClient

        @Dependency(\.repo)
        var repoClient

        public init() {}
    }
}
