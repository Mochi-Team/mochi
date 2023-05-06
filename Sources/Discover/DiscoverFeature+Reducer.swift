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
import RepoClient
import SharedModels

extension DiscoverFeature.Reducer: ReducerProtocol {
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case.view(.didAppear):
                return .merge(
                    .run { send in
                        let moduleStream = repoClient.selectedModuleStream()

                        for await module in moduleStream {
                            await send(.internal(.selectedModule(module)))
                        }
                    }
                )

            case .view(.didTapOpenModules):
                return .action(.delegate(.openModules))

            case let .view(.didTapMedia(media)):
                // TODO: Open a navigation/modal sheet for the specified media
                break

            case let .internal(.selectedModule(module)):
                state.selectedModule = module
                return fetchLatestListings(&state)

            case let .internal(.loadedListings(.success(listing))):
                state.listings = .loaded(listing)

            case let .internal(.loadedListings(.failure(error))):
                state.listings = .failed(error)

            case .delegate:
                break
            }
            return .none
        }
    }

    private func fetchLatestListings(
        _ state: inout State
    ) -> Effect<Action> {
        guard let selectedModule = state.selectedModule else {
            state.listings = .failed(.system(.moduleNotSelected))
            return .none
        }

        let module = selectedModule.module

        state.listings = .loading

        return .run { send in
            let listing = try await moduleClient.getDiscoverListings(module)
            await send(.internal(.loadedListings(.success(listing))))
        } catch: { error, send in
            if let error = error as? ModuleClient.Error {
                await send(.internal(.loadedListings(.failure(.module(error)))))
            } else {
                await send(.internal(.loadedListings(.failure(.system(.unknown)))))
            }
        }
    }
}
