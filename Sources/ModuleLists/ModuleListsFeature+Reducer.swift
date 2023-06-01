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

extension ModuleListsFeature.Reducer: Reducer {
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.didAppear):
                return .run {
                    await .internal(.fetchRepos(.init { try await databaseClient.fetch(.all) }))
                }

            case let .view(.didSelectModule(repoId, moduleId)):
                return .run { _ in
                    await repoClient.selectModule(repoId, moduleId)
                    await self.dismiss()
                }

            case let .internal(.fetchRepos(.success(repos))):
                state.repos = repos

            case let .internal(.fetchRepos(.failure(error))):
                print(error)
                state.repos = []

            case .delegate:
                break
            }
            return .none
        }
    }
}
