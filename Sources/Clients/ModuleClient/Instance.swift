//
//  Instance.swift
//
//
//  Created by ErrorErrorError on 6/3/23.
//
//

import ComposableArchitecture
import ConcurrencyExtras
import DatabaseClient
import FileClient
import Foundation
import SharedModels
import SwiftSoup
import WasmInterpreter

// MARK: - ModuleClient.Instance

public extension ModuleClient {
    struct Instance {
        let module: Module
        let instance: WasmInstance
        let hostBindings: HostBindings<WasmInstance.Memory>

        init(module: Module) throws {
            @Dependency(\.fileClient)
            var fileClient

            self.module = module
            self.instance = try .init(
                module: .init(contentsOf: fileClient.retrieveModuleFolder(module.moduleLocation)
                    .appendingPathComponent("main", isDirectory: false)
                    .appendingPathExtension("wasm"))
            )
            self.hostBindings = .init(memory: instance.memory)
            try initializeImports()
        }
    }
}

/// Available method calls
///
public extension ModuleClient.Instance {
    func search(_ query: SearchQuery) async throws -> Paging<Playlist> {
        let queryPtr = hostBindings.addToHostMemory(query)
        let resultsPtr: Int32 = try instance.exports.search(queryPtr)

        if let paging = hostBindings.getHostObject(resultsPtr) as? Paging<Any?> {
            return paging.cast()
        } else if let result = hostBindings.getHostObject(resultsPtr) as? ModuleClient.Error {
            throw result
        } else {
            throw ModuleClient.Error.nullPtr(for: #function)
        }
    }

    func discoverListings() async throws -> [DiscoverListing] {
        let resultsPtr: Int32 = try instance.exports.discover_listings()

        if let values = hostBindings.getHostObject(resultsPtr) as? [DiscoverListing] {
            return values
        } else if let result = hostBindings.getHostObject(resultsPtr) as? ModuleClient.Error {
            throw result
        } else {
            throw ModuleClient.Error.nullPtr(for: #function)
        }
    }

    func searchFilters() async throws -> [SearchFilter] {
        let resultsPtr: Int32 = try instance.exports.search_filters()
        if let values = hostBindings.getHostObject(resultsPtr) as? [SearchFilter] {
            return values
        } else if let result = hostBindings.getHostObject(resultsPtr) as? ModuleClient.Error {
            throw result
        } else {
            throw ModuleClient.Error.nullPtr(for: #function)
        }
    }

    func playlistDetails(_ id: Playlist.ID) async throws -> Playlist.Details {
        let idPtr = hostBindings.addToHostMemory(id.rawValue)
        let resultsPtr: Int32 = try instance.exports.playlist_details(idPtr)

        if let details = hostBindings.getHostObject(resultsPtr) as? Playlist.Details {
            return details
        } else if let result = hostBindings.getHostObject(resultsPtr) as? ModuleClient.Error {
            throw result
        } else {
            throw ModuleClient.Error.nullPtr(for: #function)
        }
    }

    func playlistVideos(_ request: Playlist.ItemsRequest) async throws -> Playlist.ItemsResponse {
        let requestPtr = hostBindings.addToHostMemory(request)
        let resultsPtr: Int32 = try instance.exports.playlist_episodes(requestPtr)

        if let response = hostBindings.getHostObject(resultsPtr) as? Playlist.ItemsResponse {
            return response
        } else if let result = hostBindings.getHostObject(resultsPtr) as? ModuleClient.Error {
            throw result
        } else {
            throw ModuleClient.Error.nullPtr()
        }
    }

    func playlistVideoSources(_ request: Playlist.EpisodeSourcesRequest) async throws -> [Playlist.EpisodeSource] {
        let requestPtr = hostBindings.addToHostMemory(request)
        let resultsPtr: Int32 = try instance.exports.playlist_episode_sources(requestPtr)

        if let response = hostBindings.getHostObject(resultsPtr) as? [Playlist.EpisodeSource] {
            return response
        } else if let result = hostBindings.getHostObject(resultsPtr) as? ModuleClient.Error {
            throw result
        } else {
            throw ModuleClient.Error.nullPtr()
        }
    }

    func playlistVideoServer(_ request: Playlist.EpisodeServerRequest) async throws -> Playlist.EpisodeServerResponse {
        let requestPtr = hostBindings.addToHostMemory(request)
        let resultsPtr: Int32 = try instance.exports.playlist_episode_server(requestPtr)

        if let response = hostBindings.getHostObject(resultsPtr) as? Playlist.EpisodeServerResponse {
            return response
        } else if let result = hostBindings.getHostObject(resultsPtr) as? ModuleClient.Error {
            throw result
        } else {
            throw ModuleClient.Error.nullPtr()
        }
    }
}

extension ModuleClient.Instance {
    func initializeImports() throws {
        try instance.importFunctions {
            self.envImports()
            self.coreImports()
            self.httpImports()
            self.jsonImports()
            self.htmlImports()
            self.cryptoImports()
            self.metaImports()
            self.videoImports()
        }
    }
}
