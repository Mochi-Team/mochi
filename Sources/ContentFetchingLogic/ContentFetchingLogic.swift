//
//  ContentFetchingLogic.swift
//
//
//  Created by ErrorErrorError on 7/2/23.
//
//

import ComposableArchitecture
import Foundation
import FoundationHelpers
import LoggerClient
import ModuleClient
import OrderedCollections
import SharedModels

// MARK: - Cancellable

private enum Cancellable: Hashable, CaseIterable {
    case fetchContent
}

// MARK: - ContentFetchingLogic

public struct ContentFetchingLogic: Reducer {
    public typealias State = Loadable<Groupings>
    public typealias Groupings = OrderedDictionary<Playlist.Group, Loadable<Pages>>
    public typealias Pages = OrderedDictionary<Playlist.Group.Content.Page, Loadable<Paging<Playlist.Item>>>

    public enum Action: Equatable, Sendable {
        case update(group: Playlist.Group?, page: Playlist.Group.Content.Page?, Loadable<Playlist.ItemsResponse>)
    }

    public enum Error: Swift.Error, Equatable, Sendable {
        case contentNotFound
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .update(group, page, response):
                if let group, case var .loaded(value) = state {
                    if let page, case var .loaded(contents) = value[group] {
                        contents[page] = response.flatMap { element in
                            element.contents
                                .first(where: \.groupId == group.id)?
                                .pagings
                                .first(where: \.id == page.id)
                                .flatMap { .loaded($0) } ?? .failed(Self.Error.contentNotFound)
                        }
                        value[group] = .loaded(contents)
                    } else {
                        value[group] = response.flatMap { element in
                            element.contents
                                .first(where: \.groupId == group.id)
                                .flatMap { .loaded(.init($0)) } ?? .failed(Self.Error.contentNotFound)
                        }
                    }

                    state = .loaded(value)
                } else {
                    state = response.map { .init($0) }
                }
            }
            return .none
        }
    }
}

public extension ContentFetchingLogic.State {
    mutating func clear() -> Effect<ContentFetchingLogic.Action> {
        self = .pending
        return .merge(.cancel(id: Cancellable.allCases))
    }

    mutating func fetchPlaylistContentIfNecessary(
        _ repoModuleId: RepoModuleID,
        _ playlistId: Playlist.ID,
        _ group: Playlist.Group? = nil,
        _ page: Playlist.Group.Content.Page? = nil,
        forced: Bool = false
    ) -> Effect<ContentFetchingLogic.Action> {
        @Dependency(\.moduleClient)
        var moduleClient

        @Dependency(\.logger)
        var logger

        if forced || !hasInitialized {
            self = .loading
        }

        // TODO: Validate if it needs to refetch content

//        if let group {
//            if let page {
//            }
//        }

        return .run { send in
            try await withTaskCancellation(id: Cancellable.fetchContent, cancelInFlight: true) {
                let value = try await moduleClient.withModule(id: repoModuleId) { module in
                    try await module.playlistVideos(
                        .init(
                            playlistId: playlistId,
                            groupId: group?.id,
                            pageId: page?.id,
                            itemId: nil
                        )
                    )
                }

                await send(.update(group: group, page: page, .loaded(value)))
            }
        } catch: { error, send in
            logger.error("\(#function) - \(error)")
            await send(.update(group: group, page: page, .failed(error)))
        }
    }
}

private extension ContentFetchingLogic.Pages {
    init(_ content: Playlist.Group.Content) {
        self.init()

        content.allPages.forEach { page in
            self[page] = content.pagings
                .first(where: \.id == page.id)
                .flatMap { .loaded($0) } ?? .pending
        }
    }
}

private extension ContentFetchingLogic.Groupings {
    init(_ response: Playlist.ItemsResponse) {
        self.init()
        response.allGroups.forEach { group in
            self[group] = response.contents
                .first(where: \.groupId == group.id)
                .flatMap { .loaded(.init($0)) } ?? .pending
        }
    }
}

// MARK: - ContentFetchingLogic.State + Sendable

extension ContentFetchingLogic.State: Sendable {}

// MARK: - OrderedDictionary + Sendable

extension OrderedDictionary: @unchecked Sendable where Key: Sendable, Value: Sendable {}
