//
//  ReposFeature+Reducer.swift
//  
//
//  Created ErrorErrorError on 4/18/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import Foundation
import RepoClient

extension ReposFeature.Reducer: Reducer {
    @ReducerBuilder<State, Action>
    public var body: some ReducerOf<Self> {
        Case(/Action.view) {
            BindingReducer()
        }

        Reduce { state, action in
            struct RepoURLDebounce: Hashable {}
            switch action {
            case .view(.didAppear):
                break

            case let .view(.addNewRepo(repo)):
                break

            case .view(.binding(\.$urlTextInput)):
                guard let url = URL(string: state.urlTextInput) else {
                    state.urlRepoState = nil
                    return .cancel(id: RepoURLDebounce.self)
                }

                state.urlRepoState = .loading

                return .run { [url] send in
                    try await withTaskCancellation(id: RepoURLDebounce.self, cancelInFlight: true) {
                        try await Task.sleep(nanoseconds: 1_000_000 * 1_000)
                        let repoValid = try await repoClient.validateRepo(url)
                        await send(.internal(.validateRepoURL(.loaded(.init(repo: repoValid)))))
                    }
                } catch: { error, send in
                    print(error)
                    await send(.internal(.validateRepoURL(.failed(.notValidRepo))))
                }

            case .view(.binding):
                break

            case let .internal(.validateRepoURL(loadable)):
                state.urlRepoState = loadable

            case .internal:
                break

            case .delegate:
                break
            }
            return .none
        }
    }
}
