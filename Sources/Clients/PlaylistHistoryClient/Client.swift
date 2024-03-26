//
//  Client.swift
//
//
//  Created by DeNeRr on 28.01.2024.
//

import DatabaseClient
import Dependencies
@_exported
import Foundation
import SharedModels
import Tagged
import XCTestDynamicOverlay

// MARK: - PlaylistHistoryClient

public struct PlaylistHistoryClient: Sendable {
  public var updateEpId: @Sendable (EpIdPayload) async throws -> Void
  public var fetch: @Sendable (RMP) async throws -> PlaylistHistory
  public var fetchForModule: @Sendable (String, String) async throws -> [PlaylistHistory]
  public var updateTimestamp: @Sendable (RMP, Double) async throws -> Void
  public var updateDateWatched: @Sendable (RMP) async throws -> Void
  public var observe: @Sendable (RMP) -> AsyncStream<[PlaylistHistory]>
  public var clearHistory: @Sendable () async throws -> Void
  public var removePlaylistHistory: @Sendable (RMP) async throws -> Void
}

// MARK: TestDependencyKey

extension PlaylistHistoryClient: TestDependencyKey {
  public static let testValue = Self(
    updateEpId: unimplemented("\(Self.self).updateEpId"),
    fetch: unimplemented("\(Self.self).fetch"),
    fetchForModule: unimplemented("\(Self.self).fetchForModule"),
    updateTimestamp: unimplemented("\(Self.self).updateTimestamp"),
    updateDateWatched: unimplemented("\(Self.self).updateDateWatched"),
    observe: unimplemented("\(Self.self).observe"),
    clearHistory: unimplemented("\(Self.self).clearHistory"),
    removePlaylistHistory: unimplemented("\(Self.self).removePlaylistHistory")
  )
}

extension DependencyValues {
  public var playlistHistoryClient: PlaylistHistoryClient {
    get { self[PlaylistHistoryClient.self] }
    set { self[PlaylistHistoryClient.self] = newValue }
  }
}
