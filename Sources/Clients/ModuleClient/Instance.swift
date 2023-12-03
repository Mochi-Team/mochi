//
//  Instance.swift
//
//
//  Created by ErrorErrorError on 10/28/23.
//
//

import Foundation
import JavaScriptCore
import SharedModels

public extension ModuleClient {
    // TODO: Make this a class and add support for module storage.
    struct Instance {
        private let id: RepoModuleID
        private let module: Module
        private let runtime: any JSRuntime
        private let logger: ModuleLogger

        init(id: RepoModuleID, module: Module) throws {
            self.id = id
            self.module = module
            self.logger = try ModuleLogger(id: id, directory: module.directory)
            self.runtime = try JSContext(module) { [logger] type, msg in
                switch type {
                case .log:
                    logger.log("\(msg)")
                case .debug:
                    logger.debug("\(msg)")
                case .error:
                    logger.error("\(msg)")
                case .info:
                    logger.info("\(msg)")
                case .warn:
                    logger.warn("\(msg)")
                }
            }
        }
    }
}

extension ModuleClient.Instance {
    public var logs: AsyncStream<[ModuleLoggerEvent]> { self.logger.events.values.eraseToStream() }
}

/// Available SourceModule Methods
public extension ModuleClient.Instance {
    func searchFilters() async throws -> [SearchFilter] {
        try await reportError(await runtime.searchFilters())
    }

    func search(_ query: SearchQuery) async throws -> Paging<Playlist> {
        try await reportError(await runtime.search(query))
    }

    func discoverListings(_ request: DiscoverListing.Request? = nil) async throws -> [DiscoverListing] {
        try await reportError(await runtime.discoverListings(request))
    }

    func playlistDetails(_ id: Playlist.ID) async throws -> Playlist.Details {
        try await reportError(await runtime.playlistDetails(id))
    }
}

/// Available VideoContent Methods
public extension ModuleClient.Instance {
    func playlistEpisodes(_ id: Playlist.ID, _ options: Playlist.ItemsRequestOptions?) async throws -> Playlist.ItemsResponse {
        try await reportError(await runtime.playlistEpisodes(id, options))
    }

    func playlistEpisodeSources(_ request: Playlist.EpisodeSourcesRequest) async throws -> [Playlist.EpisodeSource] {
        try await reportError(await runtime.playlistEpisodeSources(request))
    }

    func playlistEpisodeServer(_ request: Playlist.EpisodeServerRequest) async throws -> Playlist.EpisodeServerResponse {
        try await reportError(await runtime.playlistEpisodeServer(request))
    }
}

extension ModuleClient.Instance {
    private func reportError<R>(_ callback: @autoclosure () async throws -> R) async rethrows -> R {
        do {
            return try await callback()
        } catch {
            logger.error("\(error)")
            throw error
        }
    }
}
