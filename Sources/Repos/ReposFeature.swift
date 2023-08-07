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

public enum ReposFeature: Feature {
    public struct State: FeatureState {
        @SelectableState
        public var repos: IdentifiedArrayOf<Repo>
        @BindingState
        public var url: String
        public var repo: Loadable<RepoClient.RepoPayload>
        public var repoModules: [Repo.ID: Loadable<[Module.Manifest]>]
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
            repos: SelectableState<IdentifiedArrayOf<Repo>> = .init(wrappedValue: []),
            repoModules: [Repo.ID: Loadable<[Module.Manifest]>] = [:],
            url: String = "",
            repo: Loadable<RepoClient.RepoPayload> = .pending
        ) {
            self._repos = repos
            self.repoModules = repoModules
            self.url = url
            self.repo = repo
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
            case validateRepoURL(Loadable<RepoClient.RepoPayload>)
            case loadableModules(Repo.ID, Loadable<[Module.Manifest]>)
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

        public nonisolated init(store: FeatureStoreOf<ReposFeature>) {
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
