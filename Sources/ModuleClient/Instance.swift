//
//  Instance.swift
//
//
//  Created by ErrorErrorError on 6/3/23.
//
//

import ConcurrencyExtras
import Foundation
import SharedModels
import SwiftSoup
import WasmInterpreter

// MARK: - Instance

public extension ModuleClient {
    struct Instance {
        let module: Module
        let instance: WasmInstance
        let hostAllocations = LockIsolated<[PtrRef: Any?]>([:])
        var memory: WasmInstance.Memory { instance.memory }

        init(module: Module) throws {
            self.module = module
            self.instance = try .init(module: module.binaryModule)
            try initializeImports()
        }
    }
}

/// Available method calls
///
public extension ModuleClient.Instance {
    func search(_ query: SearchQuery) async throws -> Paging<Playlist> {
        let queryPtr = addToHostMemory(query)
        let resultsPtr: Int32 = try instance.exports.search(queryPtr)

        if let paging = getHostObject(resultsPtr) as? Paging<Any?> {
            return paging.cast()
        } else if let result = getHostObject(resultsPtr) as? ModuleClient.Error {
            throw result
        } else {
            throw ModuleClient.Error.nullPtr(for: #function)
        }
    }

    func discoverListings() async throws -> [DiscoverListing] {
        let resultsPtr: Int32 = try instance.exports.discover_listings()

        if let values = getHostObject(resultsPtr) as? [DiscoverListing] {
            return values
        } else if let result = getHostObject(resultsPtr) as? ModuleClient.Error {
            throw result
        } else {
            throw ModuleClient.Error.nullPtr(for: #function)
        }
    }

    func searchFilters() async throws -> [SearchFilter] {
        let resultsPtr: Int32 = try instance.exports.search_filters()
        if let values = getHostObject(resultsPtr) as? [SearchFilter] {
            return values
        } else if let result = getHostObject(resultsPtr) as? ModuleClient.Error {
            throw result
        } else {
            throw ModuleClient.Error.nullPtr(for: #function)
        }
    }

    func playlistDetails(_ id: Playlist.ID) async throws -> Playlist.Details {
        let idPtr = addToHostMemory(id.rawValue)
        let resultsPtr: Int32 = try instance.exports.playlist_details(idPtr)

        if let details = getHostObject(resultsPtr) as? Playlist.Details {
            return details
        } else if let result = getHostObject(resultsPtr) as? ModuleClient.Error {
            throw result
        } else {
            throw ModuleClient.Error.nullPtr(for: #function)
        }
    }

    func playlistVideos(_ request: Playlist.ItemsRequest) async throws -> Playlist.ItemsResponse {
        let requestPtr = addToHostMemory(request)
        let resultsPtr: Int32 = try instance.exports.playlist_episodes(requestPtr)

        if let response = getHostObject(resultsPtr) as? Playlist.ItemsResponse {
            return response
        } else if let result = getHostObject(resultsPtr) as? ModuleClient.Error {
            throw result
        } else {
            throw ModuleClient.Error.nullPtr()
        }
    }

    func playlistVideoSources(_ request: Playlist.EpisodeSourcesRequest) async throws -> [Playlist.EpisodeSource] {
        let requestPtr = addToHostMemory(request)
        let resultsPtr: Int32 = try instance.exports.playlist_episode_sources(requestPtr)

        if let response = getHostObject(resultsPtr) as? [Playlist.EpisodeSource] {
            return response
        } else if let result = getHostObject(resultsPtr) as? ModuleClient.Error {
            throw result
        } else {
            throw ModuleClient.Error.nullPtr()
        }
    }

    func playlistVideoServer(_ request: Playlist.EpisodeServerRequest) async throws -> Playlist.EpisodeServerResponse {
        let requestPtr = addToHostMemory(request)
        let resultsPtr: Int32 = try instance.exports.playlist_episode_server(requestPtr)

        if let response = getHostObject(resultsPtr) as? Playlist.EpisodeServerResponse {
            return response
        } else if let result = getHostObject(resultsPtr) as? ModuleClient.Error {
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
            self.metaStructsImports()
            self.videoStructsImports()
        }
    }

    func addToHostMemory(_ obj: Any?) -> PtrRef {
        hostAllocations.withValue { $0.add(obj) }
    }

    func getHostObject(_ ptr: PtrRef) -> Any? {
        guard let value = hostAllocations[ptr] else {
            return nil
        }
        return value
    }

    func handleErrorAlloc<R: WasmValue>(
        func _: String = #function,
        _ callback: (inout [PtrRef: Any?]) throws -> R
    ) -> R {
        hostAllocations.withValue { alloc in
            do {
                return try callback(&alloc)
            } catch let error as SwiftSoup.Exception {
                return .init(alloc.addError(.swiftSoup(error)))
            } catch let error as WasmInstance.Error {
                return .init(alloc.addError(.wasm3(error)))
            } catch let error as ModuleClient.Error {
                return .init(alloc.addError(error))
            } catch {
                return .init(alloc.addError(.unknown()))
            }
        }
    }
}
