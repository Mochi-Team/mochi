//
//  ReposFeature.swift
//
//
//  Created ErrorErrorError on 4/18/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import Foundation
import RepoClient
import SharedModels
import Styling
import SwiftUI
import Tagged
import ViewComponents

public struct ReposFeature: Feature {
    @Dependency(\.repoClient)
    var repoClient

    public init() {}

    public struct State: FeatureState {
        public var repos: IdentifiedArrayOf<Repo>
        @BindingState
        public var url: String
        public var searchedRepo: Loadable<RepoClient.RepoPayload>
        public var path: StackState<RepoPackagesFeature.State>

        public init(
            repos: IdentifiedArrayOf<Repo> = [],
            url: String = "",
            searchedRepo: Loadable<RepoClient.RepoPayload> = .pending,
            path: StackState<RepoPackagesFeature.State> = .init()
        ) {
            self.repos = repos
            self.url = url
            self.searchedRepo = searchedRepo
            self.path = path
        }
    }

    public enum Action: FeatureAction {
        public enum ViewAction: SendableAction, BindableAction {
            case didAppear
            case didAskToRefreshRepo(Repo.ID)
            case didAskToRefreshModules
            case didTapRepo(RepoPackagesFeature.State.ID)
            case didTapToAddNewRepo(RepoClient.RepoPayload)
            case didTapToDeleteRepo(Repo.ID)
            case didTapAddModule(Repo.ID, Module.ID)
            case didTapRemoveModule(Repo.ID, Module.ID)
            case binding(BindingAction<State>)
        }

        public enum DelegateAction: SendableAction {}

        public enum InternalAction: SendableAction {
            case validateRepoURL(Loadable<RepoClient.RepoPayload>)
            case loadableModules(Repo.ID, Loadable<[Module.Manifest]>)
            case observeReposResult([Repo])
            case path(StackAction<RepoPackagesFeature.State, RepoPackagesFeature.Action>)
        }

        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)
    }

    @MainActor
    public struct View: FeatureView {
        public let store: StoreOf<ReposFeature>

        @Dependency(\.dateFormatter)
        var dateFormatter

        public nonisolated init(store: StoreOf<ReposFeature>) {
            self.store = store
        }
    }
}
