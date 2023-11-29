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

// MARK: - DiscoverFeature

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
                "There Is No Module Select"
            case .system(.unknown):
                "Unknown System Error Has Occurred"
            case .module:
                "Failed to Load Module Discovery"
            }
        }
    }

    public struct Path: Reducer {
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

    @CasePathable
    @dynamicMemberLookup
    public enum Section: Equatable, Sendable {
        case home(HomeState = .init())
        case module(ModuleListingState)

        var title: String {
            switch self {
            case .home:
                "Home"
            case let .module(moduleState):
                moduleState.module.module.name
            }
        }

        var icon: URL? {
            switch self {
            case .home:
                nil
            case let .module(moduleState):
                moduleState.module.module.icon.flatMap { URL(string: $0) }
            }
        }

        public struct HomeState: Equatable, Sendable {
            public init() {}
        }

        public struct ModuleListingState: Equatable, Sendable {
            public var module: RepoClient.SelectedModule
            public var listings: Loadable<[DiscoverListing]>
        }
    }

    public struct State: FeatureState {
        public var section: Section
        public var path: StackState<Path.State>

        @PresentationState
        public var search: SearchFeature.State?

        @PresentationState
        public var moduleLists: ModuleListsFeature.State?

        public init(
            section: DiscoverFeature.Section = .home(),
            screens: StackState<Path.State> = .init(),
            search: SearchFeature.State? = nil,
            moduleLists: ModuleListsFeature.State? = nil
        ) {
            self.section = section
            self.path = screens
            self.search = search
            self.moduleLists = moduleLists
        }
    }

    @CasePathable
    public enum Action: FeatureAction {
        @CasePathable
        public enum ViewAction: SendableAction {
            case didAppear
            case didTapOpenModules
            case didTapPlaylist(Playlist)
            case didTapSearchButton
        }

        @CasePathable
        public enum DelegateAction: SendableAction {
            case playbackVideoItem(
                Playlist.ItemsResponse,
                repoModuleId: RepoModuleID,
                playlist: Playlist,
                group: Playlist.Group.ID,
                variant: Playlist.Group.Variant.ID,
                paging: PagingID,
                itemId: Playlist.Item.ID
            )
        }

        @CasePathable
        public enum InternalAction: SendableAction {
            case selectedModule(RepoClient.SelectedModule?)
            case loadedListings(RepoModuleID, Loadable<[DiscoverListing]>)
            case screens(StackAction<Path.State, Path.Action>)
            case moduleLists(PresentationAction<ModuleListsFeature.Action>)
            case search(PresentationAction<SearchFeature.Action>)
        }

        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)
    }

    @MainActor
    public struct View: FeatureView {
        public let store: StoreOf<DiscoverFeature>

        @Namespace
        public var searchAnimation

        @MainActor
        public init(store: StoreOf<DiscoverFeature>) {
            self.store = store
        }
    }

    @Dependency(\.repoClient)
    var repoClient

    @Dependency(\.moduleClient)
    var moduleClient

    public init() {}
}

public extension DiscoverFeature.State {
    mutating func clearQuery() -> Effect<DiscoverFeature.Action> {
        self.search?.clearQuery()
            .map { .internal(.search(.presented($0))) } ?? .none
    }
}
