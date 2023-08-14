//
//  AppFeature.swift
//
//
//  Created by ErrorErrorError on 4/6/23.
//
//

import Architecture
import DatabaseClient
import Discover
import Foundation
import ModuleLists
import Repos
import Search
import Settings
import SharedModels
import SwiftUI
import VideoPlayer
import ViewComponents

public struct AppFeature: Feature {
    public struct State: FeatureState {
        public var discover = DiscoverFeature.State()
        public var repos = ReposFeature.State()
        public var search = SearchFeature.State()
        public var settings = SettingsFeature.State()

        public var selected = Tab.discover

        @PresentationState
        public var videoPlayer: VideoPlayerFeature.State?

        public init(
            discover: DiscoverFeature.State = .init(),
            repos: ReposFeature.State = .init(),
            search: SearchFeature.State = .init(),
            settings: SettingsFeature.State = .init(),
            selected: AppFeature.State.Tab = Tab.discover
        ) {
            self.discover = discover
            self.repos = repos
            self.search = search
            self.settings = settings
            self.selected = selected
        }

        public enum Tab: String, CaseIterable, Sendable {
            case discover = "Discover"
            case repos = "Repos"
            case search = "Search"
            case settings = "Settings"

            var image: String {
                switch self {
                case .discover:
                    return "doc.text.image"
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
                case .discover:
                    return "doc.text.image.fill"
                case .repos:
                    return image
                case .search:
                    return image
                case .settings:
                    return "gearshape.fill"
                }
            }

            var colorAccent: Color {
                switch self {
                case .discover:
                    return .init(hue: 138 / 360, saturation: 0.33, brightness: 0.63)
                case .repos:
                    return .init(hue: 178 / 360, saturation: 0.39, brightness: 0.7)
                case .search:
                    return .init(hue: 351 / 360, saturation: 0.68, brightness: 0.81)
                case .settings:
                    return .init(hue: 27 / 360, saturation: 0.41, brightness: 0.69)
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
            case appDelegate(AppDelegateFeature.Action)
            case discover(DiscoverFeature.Action)
            case repos(ReposFeature.Action)
            case search(SearchFeature.Action)
            case settings(SettingsFeature.Action)
            case videoPlayer(PresentationAction<VideoPlayerFeature.Action>)
        }

        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)
    }

    @MainActor
    public struct View: FeatureView {
        public let store: StoreOf<AppFeature>

        @InsetValue(\.bottomNavigation)
        var bottomNavigationSize

        public nonisolated init(store: StoreOf<AppFeature>) {
            self.store = store
        }
    }

    @Dependency(\.databaseClient)
    var databaseClient

    public init() {}
}
