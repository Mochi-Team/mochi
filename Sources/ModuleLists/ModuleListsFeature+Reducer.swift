//
//  ModuleListsFeature+Reducer.swift
//  
//
//  Created ErrorErrorError on 4/23/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture

extension ModuleListsFeature.Reducer: Reducer {
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.didAppear):
                return .run {
                    .internal(.loadedRepos(await repoClient.repos()))
                }

            case let .view(.didSelectModule(repoId, moduleId)):
                return .run { send in
                    await repoClient.selectModule(repoId, moduleId)
                    await send(.delegate(.didSelectModule))
                }

            case let .internal(.loadedRepos(repos)):
                state.repos = repos

            case .delegate:
                break
            }
            return .none
        }
    }
}
