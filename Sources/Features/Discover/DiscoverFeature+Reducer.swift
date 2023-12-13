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
import Search
import SharedModels

// MARK: - DiscoverFeature

extension DiscoverFeature {
    enum Cancellables: Hashable {
        case fetchDiscoverList
    }

    @ReducerBuilder<State, Action>
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.didAppear):
                // TODO: Set default module to load or show home.
                break

            case .view(.didTapOpenModules):
                state.moduleLists = .init()

            case let .view(.didTapPlaylist(playlist)):
                guard let id = state.section.module?.module.id else {
                    break
                }
                state.path.append(.playlistDetails(.init(content: .init(repoModuleId: id, playlist: playlist))))

            case .view(.didTapSearchButton):
                state.search = SearchFeature.State(repoModuleId: state.section.module?.module.id)

            case let .internal(.selectedModule(selection)):
                if let selection {
                    state.section = .module(.init(module: selection, listings: .pending))
                } else {
                    state.section = .home()
                }
                return state.fetchLatestListings(selection)

            case let .internal(.loadedListings(id, loadable)):
                if var moduleState = state.section.module, moduleState.module.repoId == id.repoId, moduleState.module.module.id == id.moduleId {
                    moduleState.listings = loadable
                    state.section = .module(moduleState)
                }

            case let .internal(.moduleLists(.presented(.delegate(.selectedModule(repoModule))))):
                state.moduleLists = nil
                return .send(.internal(.selectedModule(repoModule)))

            case let .internal(.search(.presented(.delegate(.playlistTapped(repoModuleId, playlist))))):
                state.path.append(.playlistDetails(.init(content: .init(repoModuleId: repoModuleId, playlist: playlist))))

            case let .internal(.screens(.element(_, .playlistDetails(.delegate(.playbackVideoItem(items, id, playlist, group, variant, paging, itemId)))))):
                return .send(
                    .delegate(
                        .playbackVideoItem(
                            items,
                            repoModuleId: id,
                            playlist: playlist,
                            group: group,
                            variant: variant,
                            paging: paging,
                            itemId: itemId
                        )
                    )
                )

            case .internal(.moduleLists):
                break

            case .internal(.search):
                break

            case .internal(.screens):
                break

            case .delegate:
                break
            }
            return .none
        }
        .ifLet(\.$moduleLists, action: \.internal.moduleLists) {
            ModuleListsFeature()
        }
        .ifLet(\.$search, action: \.internal.search) {
            SearchFeature()
        }
        .forEach(\.path, action: \.internal.screens) {
            DiscoverFeature.Path()
        }
    }
}

extension DiscoverFeature.State {
    mutating func fetchLatestListings(_ selectedModule: RepoClient.SelectedModule?) -> Effect<DiscoverFeature.Action> {
        @Dependency(\.moduleClient)
        var moduleClient

        guard let selectedModule else {
            section = .home(.init())
            return .none
        }

        section = .module(.init(module: selectedModule, listings: .loading))

        let id = selectedModule.id

        return .run { send in
            try await withTaskCancellation(id: DiscoverFeature.Cancellables.fetchDiscoverList) {
                let value = try await moduleClient.withModule(id: id) { module in
                    try await module.discoverListings()
                }

                await send(
                    .internal(
                        .loadedListings(
                            id,
                            .loaded(
                                value.sorted { leftElement, rightElement in
                                    switch (leftElement.type, rightElement.type) {
                                    case (.featured, .featured):
                                        true
                                    case (_, .featured):
                                        false
                                    default:
                                        true
                                    }
                                }
                            )
                        )
                    )
                )
            }
        } catch: { error, send in
            if let error = error as? ModuleClient.Error {
                await send(.internal(.loadedListings(id, .failed(DiscoverFeature.Error.module(error)))))
            } else {
                await send(.internal(.loadedListings(id, .failed(DiscoverFeature.Error.system(.unknown)))))
            }
        }
    }
}
