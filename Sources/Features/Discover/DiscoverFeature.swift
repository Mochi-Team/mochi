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
import Search
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

    public enum Section: Equatable, Sendable {
        case home(HomeState = .init())
        case module(ModuleState)

        public struct HomeState: Equatable, Sendable {
            public init() {}
        }

        public struct ModuleState: Equatable, Sendable {
            public var repoModule: RepoClient.SelectedModule
            public var listings: Loadable<[DiscoverListing]>
        }
    }

    public struct State: FeatureState {
        // TODO: Move listings and selectedRepoModule to Section enum
//        public var section: DiscoverFeature.Section
        public var listings: Loadable<[DiscoverListing]>
        public var selectedRepoModule: RepoClient.SelectedModule?
        public var screens: StackState<Screens.State>
        public var search: SearchFeature.State

        @PresentationState
        public var moduleLists: ModuleListsFeature.State?

        var initialized = false

        public init(
            section: DiscoverFeature.Section = .home(),
            listings: Loadable<[DiscoverListing]> = .pending,
            selectedRepoModule: RepoClient.SelectedModule? = nil,
            screens: StackState<Screens.State> = .init(),
            search: SearchFeature.State = .init(),
            moduleLists: ModuleListsFeature.State? = nil
        ) {
//            self.section = section
            self.listings = listings
            self.selectedRepoModule = selectedRepoModule
            self.screens = screens
            self.search = search
            self.moduleLists = moduleLists
        }
    }

    public enum Action: FeatureAction {
        public enum ViewAction: SendableAction {
            case didAppear
            case didTapOpenModules
            case didTapPlaylist(Playlist)
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
            case search(SearchFeature.Action)
        }

        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)
    }

    @MainActor
    public struct View: FeatureView {
        public let store: StoreOf<DiscoverFeature>

        @SwiftUI.State
        var searchBarSize = CGSize.zero

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
