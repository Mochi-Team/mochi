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
import PlaylistDetails
import RepoClient
import SharedModels
import Styling
import SwiftUI
import ViewComponents

public enum DiscoverFeature: Feature {
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

    public struct Screens: ComposableArchitecture.Reducer {
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
        public var listings: Loadable<[DiscoverListing]>
        public var selectedRepoModule: RepoClient.SelectedModule?
        public var screens: StackState<Screens.State>

        var initialized = false

        @PresentationState
        public var moduleLists: ModuleListsFeature.State?

        public init(
            listings: Loadable<[DiscoverListing]> = .pending,
            selectedRepoModule: RepoClient.SelectedModule? = nil,
            screens: StackState<Screens.State> = .init(),
            moduleLists: ModuleListsFeature.State? = nil
        ) {
            self.listings = listings
            self.selectedRepoModule = selectedRepoModule
            self.screens = screens
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
                groupId: Playlist.Group.ID,
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
        public let store: FeatureStoreOf<DiscoverFeature>

        @InsetValue(\.tabNavigation)
        var bottomNavigationSize

        public nonisolated init(store: FeatureStoreOf<DiscoverFeature>) {
            self.store = store
        }
    }

    public struct Reducer: FeatureReducer {
        public typealias State = DiscoverFeature.State
        public typealias Action = DiscoverFeature.Action

        @Dependency(\.repoClient)
        var repoClient

        @Dependency(\.moduleClient)
        var moduleClient

        public init() {}
    }
}
