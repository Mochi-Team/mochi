//
//  SearchFeature+Reducer.swift
//  
//
//  Created ErrorErrorError on 4/18/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import ModuleLists
import SharedModels

extension SearchFeature.Reducer: Reducer {
    private enum Cancellables: Hashable {
        case fetchingItemsDebounce
    }

    public var body: some ReducerOf<Self> {
        Scope(state: /State.self, action: /Action.view) {
            BindingReducer()
        }

        Reduce { state, action in
            switch action {
            case .view(.didAppear):
                if state.hasLoaded {
                    break
                }
                state.hasLoaded = true
                return .run { send in
                    let selectedSync = repoClient.selectedModuleStream()

                    for await module in selectedSync {
                        await send(.internal(.loadedSelectedModule(module)))
                    }
                }

            case .view(.didTapOpenModules):
                state.moduleLists = .init()

            case .view(.didTapFilterOptions):
//                return .send(.delegate(.tappedFilterOptions))
                break

            case .view(.didClearQuery):
                state.searchQuery.query = ""
                state.items = .pending
                return .cancel(id: Cancellables.fetchingItemsDebounce)

            case let .view(.didTapPlaylist(playlist)):
                if let selectedModule = state.selectedModule {
                    state.screens.append(
                        .playlistDetails(
                            .init(
                                repoModuleID: .init(
                                    repoId: selectedModule.repoId,
                                    moduleId: selectedModule.module.id
                                ),
                                playlist: playlist
                            )
                        )
                    )
                }

            case .view(.binding(\.$searchQuery.query)):
                guard let selected = state.selectedModule else {
                    state.items = .pending
                    return .cancel(id: Cancellables.fetchingItemsDebounce)
                }

                let searchQuery = state.searchQuery

                guard !searchQuery.query.isEmpty else {
                    state.items = .pending
                    return .cancel(id: Cancellables.fetchingItemsDebounce)
                }

                state.items = .loading

                return .run { send in
                    try await withTaskCancellation(id: Cancellables.fetchingItemsDebounce, cancelInFlight: true) {
                        try await Task.sleep(nanoseconds: 1_000_000 * 600)

                        await send(
                            .internal(
                                .loadedItems(
                                    .init {
                                        try await moduleClient.withModule(id: .init(repoId: selected.repoId, moduleId: selected.module.id)) { module in
                                            try await module.search(searchQuery)
                                        }
                                    }
                                )
                            )
                        )
                    }
                }

            case .view(.binding):
                break

            case let .internal(.loadedSelectedModule(selectedModule)):
                state.selectedModule = selectedModule
                state.items = .pending
                state.searchQuery = .init(query: "")
                return .merge(
                    .cancel(id: Cancellables.fetchingItemsDebounce),
                    .run { send in
                        if let selectedModule {
                            await send(
                                .internal(
                                    .loadedSearchFilters(
                                        .init {
                                            try await moduleClient.withModule(id: .init(repoId: selectedModule.repoId, moduleId: selectedModule.module.id)) { module in
                                                try await module.searchFilters()
                                            }
                                        }
                                    )
                                )
                            )
                        }
                    }
                )

            case let .internal(.loadedSearchFilters(.success(filters))):
                state.searchFilters = filters

            case .internal(.loadedSearchFilters(.failure)):
                state.searchFilters = []

            case let .internal(.loadedItems(.success(items))):
                state.items = .loaded(items)

            case let .internal(.loadedItems(.failure(error))):
                state.items = .failed(error)

            case let .internal(.screens(.element(_, .playlistDetails(.delegate(.playbackVideoItem(items, id, playlist, groupId, itemId)))))):
                return .send(
                    .delegate(
                        .playbackVideoItem(
                            items,
                            repoModuleID: id,
                            playlist: playlist,
                            groupId: groupId,
                            itemId: itemId
                        )
                    )
                )

            case .internal(.moduleLists):
                break

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
            SearchFeature.Screens()
        }
    }
}
