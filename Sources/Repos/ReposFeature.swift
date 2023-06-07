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

    public struct State: FeatureState {
        @SelectableState
        public var repos: IdentifiedArrayOf<Repo>
        public var urlRepoState: RepoURLState
        public var repoModules: [Repo.ID: Loadable<[Module.Manifest], RepoClient.Error>]
        public var installingModules: [RepoModuleID: RepoClient.RepoModuleDownloadState] = [:]

        public var selected: RepoPackagesFeature.State? {
            $repos.element.flatMap { repo in
                .init(
                    repo: repo,
                    modules: repoModules[repo.id] ?? .pending,
                    installingModules: Dictionary(
                        uniqueKeysWithValues: installingModules.filter(\.key.repoId == repo.id)
                            .map { ($0.moduleId, $1) }
                    )
                )
            }
        }

        public init(
            repos: SelectableState<Repo> = .init(),
            repoModules: [Repo.ID: Loadable<[Module.Manifest], RepoClient.Error>] = [:],
            repoURLState: RepoURLState = .init()
        ) {
            self._repos = repos
            self.repoModules = repoModules
            self.urlRepoState = repoURLState
        }
    }

    public enum Action: FeatureAction {
        public enum ViewAction: SendableAction, BindableAction {
            case didAppear
            case didAskToRefreshRepo(Repo.ID)
            case didAskToRefreshModules
            case didTapBackButtonForOverlay
            case didTapRepo(Repo.ID)
            case didTapToAddNewRepo(RepoClient.RepoPayload)
            case didTapToDeleteRepo(Repo.ID)
            case didTapAddModule(Repo.ID, Module.ID)
            case didTapRemoveModule(Repo.ID, Module.ID)
            case binding(BindingAction<State>)
        }

        public enum DelegateAction: SendableAction {}

        public enum InternalAction: SendableAction {
            case animateSelectRepo(Repo.ID?)
            case validateRepoURL(Loadable<RepoClient.RepoPayload, RepoURLState.Error>)
            case loadableModules(Repo.ID, Loadable<[Module.Manifest], RepoClient.Error>)
            case observeReposResult([Repo])
            case observeInstalls([RepoModuleID: RepoClient.RepoModuleDownloadState])
        }

        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)
    }

    @MainActor
    public struct View: FeatureView {
        public let store: FeatureStoreOf<ReposFeature>

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

        @Dependency(\.repoClient)
        var repoClient

        public init() {}
    }
}
