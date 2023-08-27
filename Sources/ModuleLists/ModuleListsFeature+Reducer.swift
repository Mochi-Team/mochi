//
//  ModuleListsFeature+Reducer.swift
//
//
//  Created ErrorErrorError on 4/23/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import DatabaseClient
import RepoClient

extension ModuleListsFeature {
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.didAppear):
                return .run {
                    await .internal(.fetchRepos(.init { try await databaseClient.fetch(.all) }))
                }

            case let .view(.didSelectModule(repoId, moduleId)):
                guard let module = state.repos[id: repoId]?.modules[id: moduleId]?.manifest else {
                    break
                }
                return .concatenate(
                    .send(.delegate(.selectedModule(RepoClient.SelectedModule(repoId: repoId, module: module)))),
                    .run { _ in
                        await self.dismiss()
                    }
                )

            case let .internal(.fetchRepos(.success(repos))):
                state.repos = repos

            case .internal(.fetchRepos(.failure)):
                state.repos = []

            case .delegate:
                break
            }
            return .none
        }
    }
}
