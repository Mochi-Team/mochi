//
//  DiscoverFeature+Reducer.swift
//
//
//  Created by ErrorErrorError on 4/5/23.
//
//

import Architecture
import ComposableArchitecture
import ModuleClient
import ModuleLists
import PlaylistDetails
import RepoClient
import SharedModels

extension DiscoverFeature.Reducer: ReducerProtocol {
    enum Cancellables: Hashable {
        case fetchDiscoverList
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.didAppear):
                if state.initialized {
                    break
                }

                state.initialized = true

                return .merge(
                    .run { send in
                        let moduleStream = repoClient.selectedModuleStream()

                        for await module in moduleStream {
                            await send(.internal(.selectedModule(module)))
                        }
                    }
                )

            case .view(.didTapOpenModules):
                state.moduleLists = .init()

            case let .view(.didTapPlaylist(playlist)):
                guard let repoId = state.selectedRepoModule?.repoId,
                      let moduleId = state.selectedRepoModule?.module.id else {
                    break
                }
                state.screens.append(.playlistDetails(.init(repoModuleID: .init(repoId: repoId, moduleId: moduleId), playlist: playlist)))

            case let .internal(.selectedModule(selection)):
                state.selectedRepoModule = selection
                return state.fetchLatestListings(selection)

            case let .internal(.loadedListings(.success(listing))):
                state.listings = .loaded(listing)

            case let .internal(.loadedListings(.failure(error))):
                state.listings = .failed(error)

            case .internal(.moduleLists):
                break

            case let .internal(.screens(.element(_, .playlistDetails(.delegate(.playbackVideoItem(items, repoModuleID, playlist, groupId, itemId)))))):
                return .send(
                    .delegate(
                        .playbackVideoItem(
                            items,
                            repoModuleID: repoModuleID,
                            playlist: playlist,
                            groupId: groupId,
                            itemId: itemId
                        )
                    )
                )

            case .internal(.screens):
                break

            case .delegate:
                break
            }
            return .none
        }
        .ifLet(\.$moduleLists, action: /Action.internal .. Action.InternalAction.moduleLists) {
            ModuleListsFeature.Reducer()
        }
        .forEach(\.screens, action: /Action.internal .. Action.InternalAction.screens) {
            DiscoverFeature.Screens()
        }
    }
}

extension DiscoverFeature.State {
    mutating func fetchLatestListings(_ selectedModule: RepoClient.SelectedModule?) -> Effect<DiscoverFeature.Action> {
        @Dependency(\.moduleClient)
        var moduleClient

        guard let selectedModule else {
            self.listings = .failed(DiscoverFeature.Error.system(.moduleNotSelected))
            return .none
        }

        self.listings = .loading

        return .run { send in
            try await withTaskCancellation(id: DiscoverFeature.Reducer.Cancellables.fetchDiscoverList) {
                let value = try await moduleClient.withModule(id: .init(repoId: selectedModule.repoId, moduleId: selectedModule.module.id)) { module in
                    try await module.discoverListings()
                }

                await send(
                    .internal(
                        .loadedListings(
                            .success(
                                value.sorted { leftElement, rightElement in
                                    switch (leftElement.type, rightElement.type) {
                                    case (.featured, .featured):
                                        return true
                                    case (_, .`featured`):
                                        return false
                                    default:
                                        return true
                                    }
                                }
                            )
                        )
                    )
                )
            }
        } catch: { error, send in
            print(error)
            if let error = error as? ModuleClient.Error {
                await send(.internal(.loadedListings(.failure(.module(error)))))
            } else {
                await send(.internal(.loadedListings(.failure(.system(.unknown)))))
            }
        }
    }
}
