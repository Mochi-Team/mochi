//
//  AppFeature.swift
//  
//
//  Created by ErrorErrorError on 4/6/23.
//  
//

import Architecture
import Foundation
import Home
import ModuleLists
import Repos
import Search
import Settings
import SharedModels
import SwiftUI

public enum AppFeature: Feature {
    public struct Destination: ComposableArchitecture.Reducer {
        public enum State: Equatable, Sendable {
            case sheet(Sheet)
            case popup(Popup)

            public enum Sheet: Equatable, Sendable {
                case moduleLists(ModuleListsFeature.State)
            }

            public enum Popup: Equatable, Sendable {}
        }

        public enum Action: Equatable, Sendable {
            case sheet(Sheet)
            case popup(Popup)

            public enum Sheet: Equatable, Sendable {
                case moduleLists(ModuleListsFeature.Action)
            }

            public enum Popup: Equatable, Sendable {}
        }

        public var body: some ComposableArchitecture.Reducer<State, Action> {
            Scope(
                state: /State.sheet .. State.Sheet.moduleLists,
                action: /Action.sheet .. Action.Sheet.moduleLists
            ) {
                ModuleListsFeature.Reducer()
            }
        }
    }

    public struct State: FeatureState {
        public var home = HomeFeature.State()
        public var repos = ReposFeature.State()
        public var search = SearchFeature.State()
        public var settings = SettingsFeature.State()

        public var selected = Tab.home

        @PresentationState public var destination: Destination.State?

        public init(
            home: HomeFeature.State = .init(),
            repos: ReposFeature.State = .init(),
            search: SearchFeature.State = .init(),
            settings: SettingsFeature.State = .init(),
            selected: AppFeature.State.Tab = Tab.home,
            destination: Destination.State? = nil
        ) {
            self.home = home
            self.repos = repos
            self.search = search
            self.settings = settings
            self.selected = selected
            self.destination = destination
        }

        public enum Tab: String, CaseIterable, Sendable {
            case home = "Home"
            case repos = "Repos"
            case search = "Search"
            case settings = "Settings"

            var image: String {
                switch self {
                case .home:
                    return "house"
                case .repos:
                    return "globe"
                case .search:
                    return "magnifyingglass"
                case .settings:
                    return "gearshape"
                }
            }

            var selected: String {
                switch self {
                case .home:
                    return "house.fill"
                case .repos:
                    return self.image
                case .search:
                    return self.image
                case .settings:
                    return "gearshape.fill"
                }
            }
        }
    }

    public enum Action: FeatureAction {
        public enum ViewAction: SendableAction {
            case didAppear
            case didSelectTab(State.Tab)
        }

        public enum DelegateAction: SendableAction {}

        public enum InternalAction: SendableAction {
            case home(HomeFeature.Action)
            case repos(ReposFeature.Action)
            case search(SearchFeature.Action)
            case settings(SettingsFeature.Action)
            case destination(PresentationAction<Destination.Action>)
        }

        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)
    }

    @MainActor
    public struct View: FeatureView {
        public let store: FeatureStoreOf<AppFeature>

        nonisolated public init(store: FeatureStoreOf<AppFeature>) {
            self.store = store
        }
    }

    public struct Reducer: FeatureReducer {
        public typealias State = AppFeature.State
        public typealias Action = AppFeature.Action

        public init() { }
    }
}
