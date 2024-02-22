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

// MARK: - ModuleClient.Instance

extension ModuleClient {
  // TODO: Make this a class and add support for module storage.
  public struct Instance {
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
  public var logs: AsyncStream<[ModuleLoggerEvent]> { logger.events.values.eraseToStream() }
}

// swiftformat:disable hoistAwait
/// Available SourceModule Methods
extension ModuleClient.Instance {
  public func searchFilters() async throws -> [SearchFilter] {
    try await reportError(await runtime.searchFilters())
  }

  public func search(_ query: SearchQuery) async throws -> Paging<Playlist> {
    try await reportError(await runtime.search(query))
  }

  public func discoverListings(_ request: DiscoverListing.Request? = nil) async throws -> [DiscoverListing] {
    try await reportError(await runtime.discoverListings(request))
  }

  public func playlistDetails(_ id: Playlist.ID) async throws -> Playlist.Details {
    try await reportError(await runtime.playlistDetails(id))
  }
}

/// Available VideoContent Methods
extension ModuleClient.Instance {
  public func playlistEpisodes(_ id: Playlist.ID, _ options: Playlist.ItemsRequestOptions?) async throws -> Playlist.ItemsResponse {
    try await reportError(await runtime.playlistEpisodes(id, options))
  }

  public func playlistEpisodeSources(_ request: Playlist.EpisodeSourcesRequest) async throws -> [Playlist.EpisodeSource] {
    try await reportError(await runtime.playlistEpisodeSources(request))
  }

  public func playlistEpisodeServer(_ request: Playlist.EpisodeServerRequest) async throws -> Playlist.EpisodeServerResponse {
    try await reportError(await runtime.playlistEpisodeServer(request))
  }
}

extension ModuleClient.Instance {
  private func reportError<R>(_ callback: @autoclosure () async throws -> R) async rethrows -> R {
    do {
      return try await callback()
    } catch {
      let err = error as? JSValueError
      logger.error("\(error)")
      if err?.status == 403, let data = err?.data, let hostname = err?.hostname {
        throw ModuleClient.Error.jsRuntime(.requestForbidden(data: data, hostname: hostname))
      }
      throw error
    }
  }
}
