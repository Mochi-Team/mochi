//
//  SearchFeature+Reducer.swift
//
//
//  Created ErrorErrorError on 4/18/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import LoggerClient
import ModuleLists
import OrderedCollections
import SharedModels

extension SearchFeature: Reducer {
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

                // TODO: Set default module to load.
//                return .run { send in
//                    let selectedSync = repoClient.module()
//
//                    for await module in selectedSync {
//                        await send(.internal(.loadedSelectedModule(module)))
//                    }
//                }

            case .view(.didTapOpenModules):
                state.moduleLists = .init()

            case let .view(.didShowNextPageIndicator(pagingId)):
                guard var value = state.items.value, value[pagingId] == nil else {
                    break
                }

                guard let selected = state.selectedModule else {
                    break
                }

                let searchQuery = state.searchQuery

                value[pagingId] = .loading
                state.items = .loaded(value)

                logger.debug("Requesting search page: \(pagingId.rawValue)")

                return .run { send in
                    await withTaskCancellation(id: Cancellables.fetchingItemsDebounce, cancelInFlight: true) {
                        await send(
                            .internal(
                                .loadedPageResult(
                                    pagingId,
                                    .init {
                                        try await moduleClient.withModule(id: .init(repoId: selected.repoId, moduleId: selected.module.id)) { module in
                                            try await module.search(
                                                .init(
                                                    query: searchQuery,
                                                    page: pagingId
                                                )
                                            )
                                        }
                                    }
                                )
                            )
                        )
                    }
                } catch: { error, _ in
                    logger.error("There was an error fetching page w/ id: \(pagingId.rawValue) - \(error.localizedDescription)")
                }

            case .view(.didTapFilterOptions):
//                return .send(.delegate(.tappedFilterOptions))
                break

            case .view(.didClearQuery):
                state.searchQuery = ""
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

            case .view(.binding(\.$searchQuery)):
                guard let selected = state.selectedModule else {
                    state.items = .pending
                    return .cancel(id: Cancellables.fetchingItemsDebounce)
                }

                let searchQuery = state.searchQuery

                guard !searchQuery.isEmpty else {
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
                                            try await module.search(.init(query: searchQuery))
                                        }
                                    }
                                )
                            )
                        )
                    }
                } catch: { error, _ in
                    logger.error("There was an error fetching page \(error.localizedDescription)")
                }

            case .view(.binding):
                break

            case let .internal(.loadedSelectedModule(selectedModule)):
                state.selectedModule = selectedModule
                state.items = .pending
                state.searchQuery = ""
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

            case let .internal(.loadedItems(loadable)):
                state.items = loadable.map { [$0.id: .loaded($0)] }

            case let .internal(.loadedPageResult(pagingId, loadable)):
                if var value = state.items.value {
                    value[pagingId] = loadable
                    state.items = .loaded(value)
                }

            case let .internal(.screens(.element(_, .playlistDetails(.delegate(.playbackVideoItem(items, id, playlist, group, page, itemId)))))):
                return .send(
                    .delegate(
                        .playbackVideoItem(
                            items,
                            repoModuleID: id,
                            playlist: playlist,
                            group: group,
                            paging: page,
                            itemId: itemId
                        )
                    )
                )

            case let .internal(.moduleLists(.presented(.delegate(.selectedModule(repoModule))))):
                return .send(.internal(.loadedSelectedModule(repoModule)))

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
            ModuleListsFeature()
        }
        .forEach(\.screens, action: /Action.internal .. Action.InternalAction.screens) {
            SearchFeature.Screens()
        }
    }
}
