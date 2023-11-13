//
//  ContentCore.swift
//
//
//  Created by ErrorErrorError on 7/2/23.
//
//

import Architecture
import ComposableArchitecture
import Foundation
import FoundationHelpers
import LoggerClient
import ModuleClient
import OrderedCollections
import SharedModels
import Tagged

// MARK: - Cancellable

private enum Cancellable: Hashable, CaseIterable {
    case fetchContent
}

// MARK: - ContentCore

public struct ContentCore: Reducer {
    public typealias State = Loadable<[Playlist.Group]>

    public enum Action: Equatable, Sendable {
        case update(option: Playlist.ItemsRequestOptions?, Loadable<Playlist.ItemsResponse>)
    }

    public enum Error: Swift.Error, Equatable, Sendable {
        case wrongResponseType(expected: String, got: String)
        case contentNotFound
        case variantsNotFound(for: Playlist.Group.ID)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .update(option, response):
                state.update(option, response)
            }
            return .none
        }
    }
}

// MARK: - ContentAction

public protocol ContentAction {
    static func content(_: ContentCore.Action) -> Self
}

public extension ContentCore.State {
    mutating func clear<Action: FeatureAction>() -> Effect<Action> where Action.InternalAction: ContentAction {
        self = .pending
        return .merge(.cancel(id: Cancellable.fetchContent))
    }

    mutating func fetchPlaylistContentIfNecessary<Action: FeatureAction>(
        _ repoModuleId: RepoModuleID,
        _ playlistId: Playlist.ID,
        _ option: Playlist.ItemsRequestOptions? = nil,
        forced: Bool = false
    ) -> Effect<Action> where Action.InternalAction: ContentAction {
        @Dependency(\.moduleClient)
        var moduleClient

        @Dependency(\.logger)
        var logger

        // FIXME: Force should modify the respective group/variant/paging

        if forced || !hasInitialized {
            self = .loading
        }

        return .run { send in
            try await withTaskCancellation(id: Cancellable.fetchContent, cancelInFlight: true) {
                let value = try await moduleClient.withModule(id: repoModuleId) { module in
                    try await module.playlistEpisodes(playlistId, option)
                }

                await send(.internal(.content(.update(option: option, .loaded(value)))))
            }
        } catch: { error, send in
            logger.error("\(#function) - \(error)")
            await send(.internal(.content(.update(option: option, .failed(error)))))
        }
    }
}

private extension ContentCore.State {
    init(_ response: Playlist.ItemsResponse) {
        if case let .groups(array) = response {
            self = .loaded(array)
        } else {
            self = .failed(
                ContentCore.Error.wrongResponseType(
                    expected: String(describing: Playlist.ItemsResponse.groups.self),
                    got: String(describing: response.self)
                )
            )
        }
    }

    mutating func update(
        _ requested: Playlist.ItemsRequestOptions?,
        _ response: Loadable<Playlist.ItemsResponse>
    ) {
        guard case var .loaded(state) = self, let requested, var group = state[id: requested.groupID] else {
            self = response.flatMap { .init($0) }
            return
        }

        if case .group = requested {
            // Requested group content updates
            group = .init(
                id: group.id,
                number: group.number,
                altTitle: group.altTitle,
                variants: response.map(/Playlist.ItemsResponse.groups)
                    .flatMap { groups in .init(
                        value: groups,
                        error: .wrongResponseType(
                            expected: "\(Playlist.ItemsRequestOptions.self).groups",
                            got: String(describing: groups.self))
                        )
                    }
                    .flatMap { .init(value: $0?[id: requested.groupID]) }
                    .flatMap(\.variants)
            )
        } else if let variantID = requested.variantID {
            // Can only be requested if a variantID is available
            if var variant = group.variants.flatMap({ .init(value: $0[id: variantID]) }).value {
                if let pagingID = requested.pagingID {
                    // Requested paging items update
                    variant = .init(
                        id: variant.id,
                        title: variant.title,
                        icon: variant.icon,
                        pagings: variant.pagings.map { pagings in
                            var pagings = pagings
                            var page = pagings[id: pagingID]

                            page = page.flatMap { page in
                                .init(
                                    id: page.id,
                                    previousPage: page.previousPage,
                                    nextPage: page.nextPage,
                                    items: response.map(/Playlist.ItemsResponse.pagings)
                                        .flatMap { pagings in .init(
                                            value: pagings,
                                            error: .wrongResponseType(
                                                expected: "\(Playlist.ItemsRequestOptions.self).pagings",
                                                got: String(describing: pagings.self))
                                            )
                                        }
                                        .flatMap { .init(value: $0[id: pagingID]) }
                                        .map(\.items)
                                )
                            }

                            pagings[id: pagingID] = page
                            return pagings
                        }
                    )
                } else {
                    // Requested variant pagings update
                    variant = .init(
                        id: variant.id,
                        title: variant.title,
                        icon: variant.icon,
                        pagings: response.map(/Playlist.ItemsResponse.variants)
                            .flatMap { variants in .init(
                                value: variants,
                                error: .wrongResponseType(
                                    expected: "\(Playlist.ItemsRequestOptions.self).variants",
                                    got: String(describing: variants.self))
                                )
                            }
                            .flatMap { .init(value: $0[id: variantID]) }
                            .flatMap(\.pagings)
                    )
                }
            }
        } else {
            print("Ayoo wtf is this")
        }

        state[id: requested.groupID] = group
        self = .loaded(state)
    }
}

private extension Playlist.ItemsRequestOptions {
    var groupID: Playlist.Group.ID {
        switch self {
        case let .group(id):
            id
        case let .variant(id, _):
            id
        case let .page(id, _, _):
            id
        }
    }

    var variantID: Playlist.Group.Variant.ID? {
        switch self {
        case let .variant(_, id):
            id
        case let .page(_, id, _):
            id
        default:
            nil
        }
    }

    var pagingID: PagingID? {
        switch self {
        case let .page(_, _, id):
            id
        default:
            nil
        }
    }
}

private extension Loadable {
    init(value: T?, error: ContentCore.Error = .contentNotFound) {
        if let value {
            self = .loaded(value)
        } else {
            self = .failed(error)
        }
    }
}
