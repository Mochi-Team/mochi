//
//  ModuleListsFeature.swift
//
//
//  Created ErrorErrorError on 4/23/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import DatabaseClient
import RepoClient
import SharedModels

public struct ModuleListsFeature: Feature {
    public struct State: FeatureState {
        public var repos: [Repo]
        public var selected: ModuleSelectable?

        public struct ModuleSelectable: Equatable, Sendable {
            public let repoId: Repo.ID
            public let moduleId: Module.ID

            public init(
                repoId: Repo.ID,
                moduleId: Module.ID
            ) {
                self.repoId = repoId
                self.moduleId = moduleId
            }
        }

        public init(
            repos: [Repo] = [],
            selected: ModuleSelectable? = nil
        ) {
            self.repos = repos
            self.selected = selected
        }
    }

    public enum Action: FeatureAction {
        public enum ViewAction: SendableAction {
            case didAppear
            case didSelectModule(Repo.ID, Module.ID)
        }

        public enum DelegateAction: SendableAction {
            case selectedModule(RepoClient.SelectedModule?)
        }

        public enum InternalAction: SendableAction {
            case fetchRepos(TaskResult<[Repo]>)
        }

        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)
    }

    @MainActor
    public struct View: FeatureView {
        public let store: StoreOf<ModuleListsFeature>

        public nonisolated init(store: StoreOf<ModuleListsFeature>) {
            self.store = store
        }
    }

    @Dependency(\.repoClient)
    var repoClient

    @Dependency(\.databaseClient)
    var databaseClient

    @Dependency(\.dismiss)
    var dismiss

    public init() {}
}
