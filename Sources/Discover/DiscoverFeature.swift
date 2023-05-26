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
                return "There's no selected module."
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

        public enum Action: Equatable, Sendable, DismissableViewAction {
            case playlistDetails(PlaylistDetailsFeature.Action)

            public static func dismissed(_ childAction: DiscoverFeature.Screens.Action) -> Bool {
                switch childAction {
                case .playlistDetails(.view(.didTappedBackButton)):
                    return true
                default:
                    return false
                }
            }
        }

        public var body: some ComposableArchitecture.Reducer<State, Action> {
            Scope(state: /State.playlistDetails, action: /Action.playlistDetails) {
                PlaylistDetailsFeature.Reducer()
            }
        }
    }

    public struct State: FeatureState {
        public var listings: Loadable<[DiscoverListing], Error>
        public var selectedRepoModule: SelectedRepoModule?
        public var screens: StackState<Screens.State>

        var sortedListings: Loadable<[DiscoverListing], Error> {
            listings.mapValue { list in
                list.sorted { leftElement, rightElement in
                    switch (leftElement.type, rightElement.type) {
                    case (.featured, .featured):
                        return true
                    case (_, .`featured`):
                        return false
                    default:
                        return true
                    }
                }
            }
        }

        var initialized = false

        public init(
            listings: Loadable<[DiscoverListing], Error> = .pending,
            selectedRepoModule: SelectedRepoModule? = nil,
            screens: StackState<Screens.State> = .init()
        ) {
            self.listings = listings
            self.selectedRepoModule = selectedRepoModule
            self.screens = screens
        }

        public struct SelectedRepoModule: Equatable, Sendable {
            let repoId: Repo.ID
            let module: Module.Manifest
        }
    }

    public enum Action: FeatureAction {
        public enum ViewAction: SendableAction {
            case didAppear
            case didTapOpenModules
            case didTapPlaylist(Playlist)
        }

        public enum DelegateAction: SendableAction {
            case openModules
        }

        public enum InternalAction: SendableAction {
            case selectedModule(RepoClient.SelectedModule?)
            case loadedListings(Result<[DiscoverListing], Error>)
            case screens(StackAction<Screens.State, Screens.Action>)
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

        nonisolated public init(store: FeatureStoreOf<DiscoverFeature>) {
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
