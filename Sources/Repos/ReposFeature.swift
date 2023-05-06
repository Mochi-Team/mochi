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
import SwiftUI
import Tagged
import ViewComponents

public enum ReposFeature: Feature {
    public struct RepoURLState: Equatable, Sendable {
        public var repo: Loadable<RepoClient.RepoPayload, RepoURLState.Error>

        @BindingState
        public var url: String

        public init(
            url: String = "",
            repo: Loadable<RepoClient.RepoPayload, ReposFeature.RepoURLState.Error> = .pending
        ) {
            self.repo = repo
            self.url = url
        }

        public enum Error: Swift.Error, Equatable, Sendable {
            case notValidRepo
        }
    }

    public enum ModuleFetchingError: Swift.Error, Equatable, Sendable {
        case failedToConnect
        case noNetworkConnection
        case unknown
    }

    public struct State: FeatureState {
        public var repos: [Repo]
        public var loadedModules: [Repo.ID: Loadable<Date, ModuleFetchingError>]
        public var urlRepoState: RepoURLState

        public var repoPackages: RepoPackagesFeature.State?

        public init(
            repos: [Repo] = [],
            loadedModules: [Repo.ID: Loadable<Date, ModuleFetchingError>] = [:],
            repoURLState: RepoURLState = .init(),
            repoPackages: RepoPackagesFeature.State? = nil
        ) {
            self.repos = repos
            self.loadedModules = loadedModules
            self.urlRepoState = repoURLState
            self.repoPackages = repoPackages
        }
    }

    public enum Action: FeatureAction {
        public enum ViewAction: SendableAction, BindableAction {
            case didAppear
            case didAskToRefreshModules
            case didTapRepo(Repo.ID)
            case didTapToAddNewRepo(RepoClient.RepoPayload)
            case didTapToDeleteRepo(Repo.ID)
            case binding(BindingAction<State>)
        }

        public enum DelegateAction: SendableAction {}

        public enum InternalAction: SendableAction {
            case validateRepoURL(Loadable<RepoClient.RepoPayload, RepoURLState.Error>)
            case loadableModules(Repo.ID, Loadable<Date, ModuleFetchingError>)
            case fetchRepos(TaskResult<[Repo]>)
            case repoPackages(RepoPackagesFeature.Action)
        }

        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)
    }

    @MainActor
    public struct View: FeatureView {
        public let store: FeatureStoreOf<ReposFeature>

        @SwiftUI.State
        var topBarSize = SizeInset.zero

        @InsetValue(\.tabNavigation)
        var tabNavigationSize

        @Dependency(\.dateFormatter)
        var dateFormatter

        nonisolated public init(store: FeatureStoreOf<ReposFeature>) {
            self.store = store
        }
    }

    public struct Reducer: FeatureReducer {
        public typealias State = ReposFeature.State
        public typealias Action = ReposFeature.Action

        @Dependency(\.repo)
        var repoClient

        public init() {}
    }
}
