//
//  DiscoverFeature.swift
//
//
//  Created by ErrorErrorError on 4/5/23.
//
//

import Architecture
import ComposableArchitecture
import Foundation
import ModuleClient
import ModuleLists
import OrderedCollections
import PlaylistDetails
import RepoClient
import SharedModels
import Styling
import SwiftUI
import ViewComponents

public struct DiscoverFeature: Feature {
    public enum Error: Swift.Error, Equatable, Sendable {
        case system(System)
        case module(ModuleClient.Error)

        public enum System: Equatable, Sendable {
            case unknown
            case moduleNotSelected
        }

        var description: String {
            switch self {
            case .system(.moduleNotSelected):
                return "There Is No Module Select"
            case .system(.unknown):
                return "Unknown System Error Has Occurred"
            case .module(.unknown):
                return "Unknown Module Error Has Occurred"
            case .module:
                return "Failed to Load Module Discovery"
            }
        }
    }

    public struct Screens: Reducer {
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
        // TODO: Move listings and selectedRepoModule to Section enum
        public var listings: Loadable<[DiscoverListing]>
        public var selectedRepoModule: RepoClient.SelectedModule?
        public var screens: StackState<Screens.State>

        @BindingState
        public var search: Search

        @PresentationState
        public var moduleLists: ModuleListsFeature.State?

        var initialized = false

        public init(
            listings: Loadable<[DiscoverListing]> = .pending,
            selectedRepoModule: RepoClient.SelectedModule? = nil,
            screens: StackState<Screens.State> = .init(),
            search: Search = .init(),
            moduleLists: ModuleListsFeature.State? = nil
        ) {
            self.listings = listings
            self.selectedRepoModule = selectedRepoModule
            self.screens = screens
            self.search = search
            self.moduleLists = moduleLists
        }

        public enum Section: Equatable, Sendable {
            case home
            case module(ModuleListings)

            public struct ModuleListings: Equatable, Sendable {
                public let module: RepoClient.SelectedModule
                public let listings: Loadable<[DiscoverListing]>
            }
        }

        public struct Search: Equatable, Sendable {
            public var query: String
            public var searchFilters: [SearchFilter]
            public var items: Loadable<OrderedDictionary<PagingID, Loadable<Paging<Playlist>>>>

            public init(
                query: String = "",
                searchFilters: [SearchFilter] = [],
                items: Loadable<OrderedDictionary<PagingID, Loadable<Paging<Playlist>>>> = .pending
            ) {
                self.query = query
                self.searchFilters = searchFilters
                self.items = items
            }
        }
    }

    public enum Action: FeatureAction {
        public enum ViewAction: SendableAction {
            case didAppear
            case didTapOpenModules
            case didTapPlaylist(Playlist)
            case binding(BindingAction<State.Search>)
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
            case selectedModule(RepoClient.SelectedModule?)
            case loadedListings(Result<[DiscoverListing], Error>)
            case screens(StackAction<Screens.State, Screens.Action>)
            case moduleLists(PresentationAction<ModuleListsFeature.Action>)
        }

        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)
    }

    @MainActor
    public struct View: FeatureView {
        public let store: StoreOf<DiscoverFeature>

        @InsetValue(\.bottomNavigation)
        var bottomNavigationSize

        public nonisolated init(store: StoreOf<DiscoverFeature>) {
            self.store = store
        }
    }

    @Dependency(\.repoClient)
    var repoClient

    @Dependency(\.moduleClient)
    var moduleClient

    public init() {}
}
