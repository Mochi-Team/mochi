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

// MARK: - Cancellables

private enum Cancellables: Hashable {
    case fetchingItemsDebounce
}

// MARK: - SearchFeature + Reducer

extension SearchFeature: Reducer {
    public var body: some ReducerOf<Self> {
        Scope(state: \.self, action: \.view) {
            BindingReducer()
        }

        Reduce { state, action in
            switch action {
            case .view(.didAppear):
                break

            case let .view(.didShowNextPageIndicator(pagingId)):
                guard var value = state.items.value, value[pagingId] == nil else {
                    break
                }

                guard let selected = state.repoModuleId else {
                    break
                }

                let searchQuery = state.query

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
                                        try await moduleClient.withModule(id: selected) { module in
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

            case .view(.didTapClearQuery):
                return state.clearQuery()

            case let .view(.didTapPlaylist(playlist)):
                if let repoModuleId = state.repoModuleId {
                    state.searchFieldFocused = false
                    return .send(.delegate(.playlistTapped(repoModuleId, playlist)))
                }

            case .view(.binding(\.$query)):
                guard let selected = state.repoModuleId else {
                    state.items = .pending
                    return .cancel(id: Cancellables.fetchingItemsDebounce)
                }

                let searchQuery = state.query

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
                                        try await moduleClient.withModule(id: selected) { module in
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

            case .view(.binding(\.$searchFieldFocused)):
                if state.searchFieldFocused {
                    state.expandView = true
                }

            case .view(.binding(\.$expandView)):
                if state.searchFieldFocused {
                    state.searchFieldFocused = false
                }

            case .view(.binding):
                break

            case let .internal(.loadedSearchFilters(.success(filters))):
                state.filters = filters

            case .internal(.loadedSearchFilters(.failure)):
                state.filters = []

            case let .internal(.loadedItems(loadable)):
                state.items = loadable.map { [$0.id: .loaded($0)] }

            case let .internal(.loadedPageResult(pagingId, loadable)):
                if var value = state.items.value {
                    value[pagingId] = loadable
                    state.items = .loaded(value)
                }

            case .delegate:
                break
            }
            return .none
        }
    }
}

public extension SearchFeature.State {
    mutating func collapse() -> Effect<SearchFeature.Action> {
        expandView = false
        return .none
    }

    mutating func clearQuery() -> Effect<SearchFeature.Action> {
        query = ""
        items = .pending
        return .cancel(id: Cancellables.fetchingItemsDebounce)
    }

    mutating func updateModule(with repoModuleId: RepoModuleID?) -> Effect<SearchFeature.Action> {
        self.repoModuleId = repoModuleId
        return clearQuery()
    }
}
