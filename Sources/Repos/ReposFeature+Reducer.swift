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
    private enum Cancellables: Hashable {
        case repoURLDebounce
        case refreshFetchingAllRemoteModules
        case reposAsyncStream
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
            case .view(.didAppear):
                return .merge(
                    .run { send in
                        await withTaskCancellation(id: Cancellables.reposAsyncStream, cancelInFlight: true) {
                            let reposStream = repoClient.repos(.all)

                            for await repos in reposStream {
                                await send(.internal(.observeReposResult(repos)))
                            }
                        }
                    }
                )

            case .view(.didAskToRefreshModules):
                return fetchAllReposRemoteModules(state)

            case let .view(.didAskToRefreshRepo(repoId)):
//                if let repo = state.repos[id: repoId] {
//                    return .run { send in
//                        await fetchRepoModules(repo, send, forced: true)
//                    }
//                }
                break

            case let .view(.didTapToAddNewRepo(repoPayload)):
                state.url = ""
                state.searchedRepo = .pending

                return .concatenate(
                    .run { [repoPayload] in
                        try await repoClient.addRepo(repoPayload)
                    }
                )

            case let .view(.didTapToDeleteRepo(repoId)):
                return .merge(
                    .run { _ in
                        try await Task.sleep(nanoseconds: 1_000_000 * 500)
                        try await repoClient.removeRepo(repoId)
                    },
                    .cancel(id: Cancellables.fetchRemoteRepoModules(repoId))
                )

            case let .view(.didTapRepo(repoId)):
                guard let repo = state.repos[id: repoId] else { break }
                state.path.append(RepoPackagesFeature.State(repo: repo))

            case let .view(.didTapAddModule(repoId, moduleId)):
//                guard state.selected?.repo.id == repoId else { break }
//                guard let manifest = state.selected?.packages.value?.map(\.latestModule).first(where: \.id == moduleId) else { break}

//                return .run { await repoClient.addModule(repoId, manifest) }
                break

            case let .view(.didTapRemoveModule(repoId, moduleId)):
                return .run { _ in
                    try await Task.sleep(nanoseconds: 1_000_000 * 500)
                    try await repoClient.removeModule(repoId, moduleId)
                }

            case .view(.binding(\.$url)):
                guard let url = URL(string: state.url.lowercased()) else {
                    state.searchedRepo = .pending
                    return .cancel(id: Cancellables.repoURLDebounce)
                }

                state.searchedRepo = .loading

                return .run { send in
                    try await withTaskCancellation(id: Cancellables.repoURLDebounce, cancelInFlight: true) {
                        try await Task.sleep(nanoseconds: 1_000_000 * 1_250)
                        let repoValid = try await repoClient.validateRepo(url)
                        await send(.internal(.validateRepoURL(.loaded(repoValid))))
                    }
                } catch: { error, send in
                    print(error)
                    await send(.internal(.validateRepoURL(.failed(Error.notValidRepo))))
                }

            case .view(.binding):
                break

            case let .internal(.validateRepoURL(loadable)):
                state.searchedRepo = loadable

            case let .internal(.loadableModules(repoId, loadable)):
//                state.repoModules[repoId] = loadable
                break

            case let .internal(.observeReposResult(repos)):
                state.repos = .init(uniqueElements: repos)

            case .internal(.path):
                break

//            case let .internal(.repo(id, .delegate(.didTapCloseButton))):
//                break
//                if state.selected?.id == id {
//                    state.selection = nil
//                }

            case .delegate:
                break
            }
            return .none
        }
        .forEach(\.path, action: /Action.internal .. Action.InternalAction.path) {
            RepoPackagesFeature()
        }
    }

    // TODO: Move logic to dependency
    private func fetchAllReposRemoteModules(
        _ state: State,
        forced: Bool = true
    ) -> Effect<Action> {
        .run { send in
            await withTaskCancellation(id: Cancellables.refreshFetchingAllRemoteModules, cancelInFlight: true) {
                await withTaskGroup(of: Void.self) { group in
                    for repo in state.repos {
//                        group.addTask {
//                            await fetchRepoModules(
//                                repo,
//                                send,
//                                alreadyRequested: state.repoModules[repo.id].map(\.hasInitialized) ?? false,
//                                forced: forced
//                            )
//                        }
                    }
                }
            }
        }
    }

    // TODO: Move logic to dependency
    private func fetchRepoModules(_ repo: Repo, _ send: Send<Action>, alreadyRequested: Bool = false, forced: Bool = true) async {
        if forced || !alreadyRequested {
            await withTaskCancellation(id: Cancellables.fetchRemoteRepoModules(repo.id), cancelInFlight: true) {
                await send(.internal(.loadableModules(repo.id, .loading)))

                do {
                    try await Task.sleep(nanoseconds: 1_000_000 * 500)
                    let modules = try await repoClient.fetchRepoModules(repo)
                    await send(.internal(.loadableModules(repo.id, .loaded(modules))))
                } catch {
                    print(error)
                    await send(.internal(.loadableModules(repo.id, .failed(RepoClient.Error.failedToFindRepo))))
                }
            }
        }
    }
}
