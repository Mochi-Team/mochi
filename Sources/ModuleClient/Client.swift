//
//  Client.swift
//  
//
//  Created ErrorErrorError on 4/10/23.
//  Copyright © 2023. All rights reserved.
//

import Dependencies
import Foundation
import SharedModels
import SwiftSoup
import WasmInterpreter
import XCTestDynamicOverlay

public struct ModuleClient: Sendable {
    public let searchFilters: @Sendable (Module) async throws -> [SearchFilter]
    public let search: @Sendable (Module, SearchQuery) async throws -> Paging<Playlist>
    public let getDiscoverListings: @Sendable (Module) async throws -> [DiscoverListing]
    public let getPlaylistDetails: @Sendable (Module, Playlist.ID) async throws -> Playlist.Details

    public let getPlaylistVideos: @Sendable (Module, Playlist.ItemsRequest) async throws -> Playlist.ItemsResponse
}

extension ModuleClient {
    public enum Error: Swift.Error, Equatable, Sendable {
        case wasm3(WasmInstance.Error)
        case nullPtr(for: String = #function, message: String = "")
        case castError(for: String = #function, got: String = "", expected: String = "")
        case swiftSoup(for: String = #function, SwiftSoup.Exception)
        case indexOutOfBounds(for: String = #function)
        case unknown(for: String = #function)
    }
}

extension SwiftSoup.Exception: Equatable {
    public static func == (lhs: Exception, rhs: Exception) -> Bool {
        switch (lhs, rhs) {
        case let (.Error(typeOne, messageOne), .Error(typeTwo, messageTwo)):
            return typeOne == typeTwo && messageOne == messageTwo
        }
    }
}

extension ModuleClient: TestDependencyKey {
    public static let testValue = Self(
        searchFilters: unimplemented(),
        search: unimplemented(),
        getDiscoverListings: unimplemented(),
        getPlaylistDetails: unimplemented(),
        getPlaylistVideos: unimplemented()
    )
}

extension DependencyValues {
    public var moduleClient: ModuleClient {
        get { self[ModuleClient.self] }
        set { self[ModuleClient.self] = newValue }
    }
}
