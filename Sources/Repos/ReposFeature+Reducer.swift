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

extension ReposFeature.Reducer: Reducer {
    private struct RepoURLDebounce: Hashable {}
    private struct RefreshFetchingAllModules: Hashable {}
    private struct ReposAsyncStreamId: Hashable {}

    @ReducerBuilder<State, Action>
    public var body: some ReducerOf<Self> {
        Case(/Action.view) {
            BindingReducer()
        }

        Reduce { state, action in
            switch action {
            case .view(.didAppear):
                return .run { send in
                    await withTaskCancellation(id: ReposAsyncStreamId.self, cancelInFlight: true) {
                        let reposStream = repoClient.repos(.all)

                        for await repos in reposStream {
                            await send(.internal(.fetchRepos(.success(repos))))
                            await fetchAllReposModules(repos, send)
                        }
                    }
                }

            case .view(.didAskToRefreshModules):
                struct RefreshDebounce: Hashable {}
                return .run { [state] send in
                    await withTaskCancellation(id: RefreshDebounce.self, cancelInFlight: true) {
                        await fetchAllReposModules(state.repos, send)
                    }
                }

            case let .view(.didTapToAddNewRepo(repoPayload)):
                state.urlRepoState.url = ""
                state.urlRepoState.repo = .pending

                return .concatenate(
                    .run { [repoPayload] in
                        try await repoClient.installRepo(repoPayload)
                    }
                )

            case let .view(.didTapToDeleteRepo(repoId)):
                return .merge(
                    .run { _ in
                        try await Task.sleep(nanoseconds: 1_000_000 * 500)
                        try await repoClient.removeRepo(repoId)
                    },
                    .cancel(id: repoId)
                )

            case let .view(.didTapRepo(repoId)):
                guard let repo = state.repos.first(where: \.id == repoId) else {
                    break
                }

                state.repoPackages = .init(repo: repo)

            case .view(.binding(\.urlRepoState.$url)):
                guard let url = URL(string: state.urlRepoState.url) else {
                    state.urlRepoState.repo = .pending
                    return .cancel(id: RepoURLDebounce.self)
                }

                state.urlRepoState.repo = .loading

                return .run { [url] send in
                    try await withTaskCancellation(id: RepoURLDebounce.self, cancelInFlight: true) {
                        try await Task.sleep(nanoseconds: 1_000_000 * 1_250)
                        let repoValid = try await repoClient.validateRepo(url)
                        await send(.internal(.validateRepoURL(.loaded(repoValid))))
                    }
                } catch: { error, send in
                    print(error)
                    await send(.internal(.validateRepoURL(.failed(.notValidRepo))))
                }

            case .view(.binding):
                break

            case let .internal(.validateRepoURL(loadable)):
                state.urlRepoState.repo = loadable

            case let .internal(.loadableModules(repoId, loadable)):
                state.loadedModules[repoId] = loadable

            case let .internal(.fetchRepos(.success(repos))):
                state.repos = repos

            case let .internal(.fetchRepos(.failure(error))):
                print(error)
                state.repos = []

            case let .internal(.repoPackages(.delegate(delegate))):
                switch delegate {
                case .backButtonTapped:
                    state.repoPackages = nil
                }

            case .internal(.repoPackages):
                break

            case .delegate:
                break
            }
            return .none
        }

        // WIP: Can't use built-in ifLet due to presentation binding
        EmptyReducer()
            .ifLet(\.repoPackages, action: /Action.internal..Action.InternalAction.repoPackages) {
                RepoPackagesFeature.Reducer()
            }
    }

    private func fetchAllReposModules(_ repos: [Repo], _ send: Send<Action>) async {
        await withTaskCancellation(id: RefreshFetchingAllModules.self, cancelInFlight: true) {
            await withTaskGroup(of: Void.self) { group in
                for repo in repos {
                    group.addTask {
                        await fetchRepoModules(repo, send)
                    }
                }
            }
        }
    }

    private func fetchRepoModules(_ repo: Repo, _ send: Send<Action>) async {
        await withTaskCancellation(id: repo.id, cancelInFlight: true) {
            await send(.internal(.loadableModules(repo.id, .loading)))

            do {
                try await Task.sleep(nanoseconds: 1_000_000 * 500)
                _ = try await repoClient.fetchRepoModules(repo)
                await send(.internal(.loadableModules(repo.id, .loaded(.init()))))
            } catch {
                print(error)
                await send(.internal(.loadableModules(repo.id, .failed(.failedToConnect))))
            }
        }
    }
}
