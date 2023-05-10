//
//  SearchFeature+Reducer.swift
//  
//
//  Created ErrorErrorError on 4/18/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import SharedModels

extension SearchFeature.Reducer: Reducer {
    struct FetchingItemsDebounce: Hashable {}

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
                return .action(.delegate(.tappedOpenModules))

            case .view(.didTapFilterOptions):
                break
//                return .action(.delegate(.tappedFilterOptions))

            case .view(.didClearQuery):
                state.searchQuery.query = ""
                state.items = .pending
                return .cancel(id: FetchingItemsDebounce.self)

            case .view(.binding(\.$searchQuery.query)):
                guard let selected = state.selectedModule else {
                    state.items = .pending
                    return .cancel(id: FetchingItemsDebounce.self)
                }

                let searchQuery = state.searchQuery

                guard !searchQuery.query.isEmpty else {
                    state.items = .pending
                    return .cancel(id: FetchingItemsDebounce.self)
                }

                state.items = .loading

                return .run { send in
                    try await withTaskCancellation(id: FetchingItemsDebounce.self, cancelInFlight: true) {
                        try await Task.sleep(nanoseconds: 1_000_000 * 1_000)

                        await send(.internal(.loadedItems(.init { try await moduleClient.search(selected.module, searchQuery) })))
                    }
                }

            case .view(.binding):
                break

            case let .internal(.loadedSelectedModule(selectedModule)):
                state.selectedModule = selectedModule
                state.items = .pending
                state.searchQuery = .init(query: "")
                return .merge(
                    .cancel(id: FetchingItemsDebounce.self),
                    .run { send in
                        if let selectedModule {
                            await send(.internal(.loadedSearchFilters(.init { try await moduleClient.searchFilters(selectedModule.module) })))
                        }
                    }
                )

            case let .internal(.loadedSearchFilters(.success(filters))):
                state.searchFilters = filters

            case .internal(.loadedSearchFilters(.failure)):
                state.searchFilters = []

            case let .internal(.loadedItems(.success(items))):
                state.items = .loaded(items)

            case .internal(.loadedItems(.failure)):
                state.items = .failed(.unknown())

            case .delegate:
                break
            }
            return .none
        }
    }
}
