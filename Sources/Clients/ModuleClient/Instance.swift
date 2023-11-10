//
//  Instance.swift
//
//
//  Created by ErrorErrorError on 10/28/23.
//
//

import Foundation
import JavaScriptCore
import os
import SharedModels
import WebKit

public extension ModuleClient {
    struct Instance {
        private let module: Module
        private let runtime: any JSRuntime
        private let logger: Logger

        init(module: Module) throws {
            self.module = module
            self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.errorerrorerror.mochi", category: "module-\(module.id.rawValue)")
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
                    logger.warning("\(msg)")
                }
            }
        }
    }
}

public extension ModuleClient.Instance {
    func search(_ query: SearchQuery) async throws -> Paging<Playlist> {
        try await reportError(await runtime.search(query))
    }

    func discoverListings() async throws -> [DiscoverListing] {
        try await reportError(await runtime.discoverListings())
    }

    func searchFilters() async throws -> [SearchFilter] {
        try await reportError(await runtime.searchFilters())
    }

    func playlistDetails(_ id: Playlist.ID) async throws -> Playlist.Details {
        try await reportError(await runtime.playlistDetails(id))
    }

    func playlistEpisodes(_ request: Playlist.ItemsRequest) async throws -> Playlist.ItemsResponse {
        try await reportError(await runtime.playlistEpisodes(request))
    }

    func playlistEpisodeSources(_ request: Playlist.EpisodeSourcesRequest) async throws -> [Playlist.EpisodeSource] {
        try await reportError(await runtime.playlistEpisodeSources(request))
    }

    func playlistEpisodeServer(_ request: Playlist.EpisodeServerRequest) async throws -> Playlist.EpisodeServerResponse {
        try await reportError(await runtime.playlistEpisodeServer(request))
    }

    private func reportError<R>(_ callback: @autoclosure @escaping () async throws -> R) async rethrows -> R {
        do {
            return try await callback()
        } catch {
            self.logger.error("\(error)")
            throw error
        }
    }
}
