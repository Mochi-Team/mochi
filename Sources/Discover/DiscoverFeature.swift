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
import RepoClient
import SharedModels
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
                return "Module Not Selected"
            case .system(.unknown):
                return "Unknown System Error Has Occurred"
            case .module(.unknown):
                return "Unknown Module Error Has Occurred"
            case .module:
                return "Failed to Load Module Discovery"
            }
        }
    }

    public struct State: FeatureState {
        public var listings: Loadable<[DiscoverListing], Error>
        public var selectedModule: RepoClient.SelectedModule?

        var hasSetUp = false

        public init(
            listings: Loadable<[DiscoverListing], Error> = .pending,
            selectedModule: RepoClient.SelectedModule? = nil
        ) {
            self.listings = listings
            self.selectedModule = selectedModule
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

        @SwiftUI.State
        var topBarSizeInset = SizeInset.zero

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
