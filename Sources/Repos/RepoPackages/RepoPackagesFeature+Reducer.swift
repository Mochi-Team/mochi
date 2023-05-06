//
//  RepoPackagesFeature+Reducer.swift
//  
//
//  Created ErrorErrorError on 5/4/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import RepoClient
import SharedModels

extension RepoPackagesFeature.Reducer: Reducer {
    private struct LoadedRepoModulesCancellable: Hashable {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.didAppear):
                let repo = state.repo
                state.packages = .loading
                return .run { send in
                    await withTaskCancellation(id: LoadedRepoModulesCancellable.self, cancelInFlight: true) {
                        await send(.internal(.loadedRepoModules(.init { try await repoClient.fetchRepoModules(repo) })))
                    }
                }
                .animation()

            case let .view(.didTapInstallModule(moduleId)):
                let repoId = state.repo.id

                guard let manifest = state.packages.value?.map(\.latestModule).first(where: \.id == moduleId) else {
                    break
                }

                return .run {
                    try await repoClient.installModule(repoId, manifest)
                }

            case let .view(.didTapRemoveModule(moduleId)):
                let repoId = state.repo.id

                return .run {
                    try await repoClient.removeModule(repoId, moduleId)
                }

            case .view(.didTapBackButton):
                return .action(.delegate(.backButtonTapped))

            case let .internal(.loadedRepoModules(.success(modules))):
                state.packages = .loaded(
                    Dictionary(grouping: modules, by: \.id)
                        .map(\.value)
                        .filter { !$0.isEmpty }
                        .sorted { $0.latestModule.name < $1.latestModule.name }
                )

            case let .internal(.loadedRepoModules(.failure(error))):
                state.packages = .failed((error as? RepoClient.Error) ?? .failedToFindRepo)

            case .delegate:
                break
            }
            return .none
        }
    }
}

extension [Module.Manifest] {
    var latestModule: Module.Manifest {
        self.max { $0.version < $1.version }.unsafelyUnwrapped
    }
}
