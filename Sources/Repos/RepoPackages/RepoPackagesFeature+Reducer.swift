//
//  RepoPackagesFeature+Reducer.swift
//  
//
//  Created by ErrorErrorError on 8/16/23.
//  
//

import Architecture
import ComposableArchitecture
import Foundation
import RepoClient

extension RepoPackagesFeature {
    private enum Cancellable: Hashable {
        case fetchingModules
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.didAppear):
                let repoId = state.repo.id
                return .merge(
                    state.fetchRemoteModules(),
                    .run { send in
                        let stream = repoClient.moduleDownloads()
                        for await value in stream {
                            let filteredRepo = value.filter(\.key.repoId == repoId)
                            let mapped = Dictionary(uniqueKeysWithValues: filteredRepo.map { ($0.moduleId, $1) })
                            await send(.internal(.downloadStates(mapped)))
                        }
                    }
                )

            case .view(.didTapToRefreshRepo):
                return state.fetchRemoteModules(forced: true)

            case let .view(.didTapAddModule(moduleId)):
                guard let manifest = state.packages.value?.map(\.latestModule).first(where: \.id == moduleId) else { break}
                let repoId = state.repo.id

                return .run { await repoClient.addModule(repoId, manifest) }

            case let .view(.didTapRemoveModule(moduleId)):
                if let module = state.repo.modules.first(where: \.id == moduleId) {
                    state.repo.modules.remove(module)
                }

                let repoId = state.repo.id
                return .merge(
                    .run { try await repoClient.removeModule(repoId, moduleId) },
                    .send(.delegate(.removeModule(.init(repoId: state.repo.id, moduleId: moduleId))))
                )

            case .view(.didTapClose):
                return .merge(
                    .cancel(id: Cancellable.fetchingModules),
                    .run { _ in await dismiss() }
                )

            case let .internal(.repoModules(modules)):
                state.fetchedModules = modules
                state.packages = modules.map { manifests in
                        Dictionary(grouping: manifests, by: \.id)
                            .map(\.value)
                            .filter { !$0.isEmpty }
                            .sorted { $0.latestModule.name < $1.latestModule.name }
                    }

            case let .internal(.downloadStates(modules)):
                state.downloadStates = modules

            case .delegate:
                break
            }
            return .none
        }
    }
}

extension RepoPackagesFeature.State {
    mutating func fetchRemoteModules(forced: Bool = false) -> Effect<RepoPackagesFeature.Action> {
        @Dependency(\.repoClient)
        var repoClient

        guard !fetchedModules.hasInitialized || forced else {
            return .none
        }

        self.fetchedModules = .loading

        let id = repo.id

        return .run { send in
            try await withTaskCancellation(id: RepoPackagesFeature.Cancellable.fetchingModules, cancelInFlight: true) {
                let modules = try await repoClient.fetchRemoteRepoModules(id)
                await send(.internal(.repoModules(.loaded(modules))))
            }
        } catch: { error, send in
            await send(.internal(.repoModules(.failed(error))))
        }
    }
}
