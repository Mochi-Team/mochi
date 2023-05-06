//
//  RepoPackagesFeature.swift
//  
//
//  Created ErrorErrorError on 5/4/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import RepoClient
import Semver
import SharedModels
import SwiftUI
import Tagged
import ViewComponents

public enum RepoPackagesFeature: Feature {
    public struct State: FeatureState {
        public init(
            repo: Repo,
            packages: Loadable<[[Module.Manifest]], RepoClient.Error> = .pending,
            installedModules: [Module] = [],
            installingModules: [Module.ID: Double] = [:]
        ) {
            self.repo = repo
            self.packages = packages
            self.installedModules = installedModules
            self.installingModules = installingModules
        }

        public let repo: Repo
        public var packages: Loadable<[[Module.Manifest]], RepoClient.Error>
        public var installedModules: [Module]
        public var installingModules: [Module.ID: Double]
    }

    public enum Action: FeatureAction {
        public enum ViewAction: SendableAction {
            case didAppear
            case didTapBackButton
            case didTapInstallModule(Module.ID)
            case didTapRemoveModule(Module.ID)
        }

        public enum DelegateAction: SendableAction {
            case backButtonTapped
        }

        public enum InternalAction: SendableAction {
            case loadedRepoModules(TaskResult<[Module.Manifest]>)
        }

        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)
    }

    @MainActor
    public struct View: FeatureView {
        public let store: FeatureStoreOf<RepoPackagesFeature>

        @SwiftUI.State
        var topBarSizeInset: SizeInset = .zero

        @InsetValue(\.tabNavigation)
        var tabNavigationInset

        nonisolated public init(store: FeatureStoreOf<RepoPackagesFeature>) {
            self.store = store
        }
    }

    public struct Reducer: FeatureReducer {
        public typealias State = RepoPackagesFeature.State
        public typealias Action = RepoPackagesFeature.Action

        @Dependency(\.repo)
        var repoClient

        public init() {}
    }
}
