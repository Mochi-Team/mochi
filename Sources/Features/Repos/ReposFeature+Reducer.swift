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
import SharedModels
import Styling

extension ReposFeature {
    enum Cancellables: Hashable {
        case repoURLDebounce
        case refreshFetchingAllRemoteModules
        case loadRepos
        case fetchRemoteRepoModules(Repo.ID)
        case observeInstallingModules
    }

    private enum Error: Swift.Error {
        case notValidRepo
    }

    @ReducerBuilder<State, Action>
    public var body: some ReducerOf<Self> {
        Case(/Action.view) {
            BindingReducer()
        }

        Reduce { state, action in
            switch action {
            case .view(.onTask):
                return .run { send in
                    for await value in repoClient.repos(.all) {
                        await send(.internal(.loadRepos(value)))
                    }
                }

            case .view(.didTapRefreshRepos):
                break

            case let .view(.didTapAddNewRepo(repoPayload)):
                state.url = ""
                state.searchedRepo = .pending

                return .run { try await repoClient.addRepo(repoPayload) }

            case let .view(.didTapDeleteRepo(repoId)):
                return .merge(
                    .run { _ in
                        try await Task.sleep(nanoseconds: 1_000_000 * 500)
                        try await repoClient.deleteRepo(repoId)
                    },
                    .cancel(id: Cancellables.fetchRemoteRepoModules(repoId)),
                    .run { try await moduleClient.removeCachedModules(repoId) }
                )

            case let .view(.didTapRepo(repoId)):
                guard let repo = state.repos[id: repoId] else {
                    break
                }
                state.path.append(RepoPackagesFeature.State(repo: repo))

            case .view(.binding(\.$url)):
                guard let url = URL(string: state.url.lowercased()) else {
                    state.searchedRepo = .pending
                    return .cancel(id: Cancellables.repoURLDebounce)
                }

                state.searchedRepo = .loading

                return .run { send in
                    try await withTaskCancellation(id: Cancellables.repoURLDebounce, cancelInFlight: true) {
                        try await Task.sleep(nanoseconds: 1_000_000 * 1_250)
                        try await send(.internal(.validateRepoURL(.loaded(repoClient.validate(url)))))
                    }
                } catch: { error, send in
                    print(error)
                    await send(.internal(.validateRepoURL(.failed(Error.notValidRepo))))
                }

            case .view(.binding):
                break

            case let .internal(.validateRepoURL(loadable)):
                state.searchedRepo = loadable

            case let .internal(.loadRepos(repos)):
                state.repos = .init(uniqueElements: repos)

            case .internal(.path(.element(_, .delegate))):
                break

            case .internal(.path):
                break

            case .delegate:
                break
            }
            return .none
        }
        .forEach(\.path, action: /Action.internal .. Action.InternalAction.path) {
            RepoPackagesFeature()
        }
    }
}
