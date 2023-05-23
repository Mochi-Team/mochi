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
import MediaDetails
import ModuleClient
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
            case mediaDetails(MediaDetailsFeature.State)
        }

        public enum Action: Equatable, Sendable, DismissableViewAction {
            case mediaDetails(MediaDetailsFeature.Action)

            public static func dismissed(_ childAction: DiscoverFeature.Screens.Action) -> Bool {
                switch childAction {
                case .mediaDetails(.view(.didTappedBackButton)):
                    return true
                default:
                    return false
                }
            }
        }

        public var body: some ComposableArchitecture.Reducer<State, Action> {
            Scope(state: /State.mediaDetails, action: /Action.mediaDetails) {
                MediaDetailsFeature.Reducer()
            }
        }
    }

    public struct State: FeatureState {
        public var listings: Loadable<[DiscoverListing], Error>
        public var selectedModule: Module.Manifest?
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

        var hasSetUp = false

        public init(
            listings: Loadable<[DiscoverListing], Error> = .pending,
            selectedModule: Module.Manifest? = nil,
            screens: StackState<Screens.State> = .init()
        ) {
            self.listings = listings
            self.selectedModule = selectedModule
            self.screens = screens
        }
    }

    public enum Action: FeatureAction {
        public enum ViewAction: SendableAction {
            case didAppear
            case didTapOpenModules
            case didTapMedia(Media)
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

        @Dependency(\.repo)
        var repoClient

        @Dependency(\.moduleClient)
        var moduleClient

        public init() {}
    }
}
