//
//  HomeFeature.swift
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

public enum HomeFeature: Feature {
    public enum Error: Swift.Error, Equatable, Sendable {
        case system(System)
        case module(ModuleClient.Error)

        public enum System: Equatable, Sendable {
            case unknown
            case moduleNotSelected
        }
    }

    public struct State: FeatureState {
        public var listings: Loadable<[DiscoverListing], Error>
        public var selectedModule: RepoClient.SelectedModule?

        public init(
            listings: Loadable<[DiscoverListing], Error> = .loading,
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
        @InsetValue(\.tabNavigation) var tabNavigationSize
        @SwiftUI.State var optionSelectionSize = SizeInset.zero

        public let store: FeatureStoreOf<HomeFeature>

        nonisolated public init(store: FeatureStoreOf<HomeFeature>) {
            self.store = store
        }
    }

    public struct Reducer: FeatureReducer {
        public typealias State = HomeFeature.State
        public typealias Action = HomeFeature.Action

        @Dependency(\.repo)
        var repoClient

        @Dependency(\.moduleClient)
        var moduleClient

        public init() {}
    }
}
