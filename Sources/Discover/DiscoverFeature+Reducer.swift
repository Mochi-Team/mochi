//
//  DiscoverFeature+Reducer.swift
//  
//
//  Created by ErrorErrorError on 4/5/23.
//  
//

import Architecture
import ComposableArchitecture
import MediaDetails
import ModuleClient
import RepoClient
import SharedModels

extension DiscoverFeature.Reducer: ReducerProtocol {
    enum Cancellables: Hashable {
        case fetchDiscoverList
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case.view(.didAppear):
                if state.hasSetUp {
                    break
                }

                state.hasSetUp = true

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
                state.screens.append(.mediaDetails(.init(media: media)))

            case let .internal(.selectedModule(selection)):
                state.selectedModule = selection?.module.manifest
                return fetchLatestListings(&state, selection)

            case let .internal(.loadedListings(.success(listing))):
                state.listings = .loaded(listing)

            case let .internal(.loadedListings(.failure(error))):
                state.listings = .failed(error)

            case let .internal(.screens(.popFrom(id: id))):
                state.screens.pop(from: id)

            case .internal(.screens):
                break

            case .delegate:
                break
            }
            return .none
        }
        .forEach(\.screens, action: /Action.internal..Action.InternalAction.screens) {
            DiscoverFeature.Screens()
        }
    }

    private func fetchLatestListings(
        _ state: inout State,
        _ selectedModule: RepoClient.SelectedModule?
    ) -> Effect<Action> {
        guard let selectedModule else {
            state.listings = .failed(.system(.moduleNotSelected))
            return .none
        }

        state.listings = .loading

        return .run { send in
            try await withTaskCancellation(id: Cancellables.fetchDiscoverList) {
                let listing = try await moduleClient.getDiscoverListings(selectedModule.module)
                await send(.internal(.loadedListings(.success(listing))))
            }
        } catch: { error, send in
            if let error = error as? ModuleClient.Error {
                await send(.internal(.loadedListings(.failure(.module(error)))))
            } else {
                await send(.internal(.loadedListings(.failure(.system(.unknown)))))
            }
        }
    }
}
