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
  public var fetch: @Sendable (String) async throws -> PlaylistHistory
  public var observeModule: @Sendable (String) -> AsyncStream<[PlaylistHistory]>
  public var updateTimestamp: @Sendable (String, Double) async throws -> Void
  public var observe: @Sendable (String) -> AsyncStream<[PlaylistHistory]>
}

// MARK: TestDependencyKey

extension PlaylistHistoryClient: TestDependencyKey {
  public static let testValue = Self(
    updateEpId: unimplemented("\(Self.self).updateEpId"),
    fetch: unimplemented("\(Self.self).fetch"),
    observeModule: unimplemented("\(Self.self).observeModule"),
    updateTimestamp: unimplemented("\(Self.self).updateTimestamp"),
    observe: unimplemented("\(Self.self).observe")
  )
}

extension DependencyValues {
  public var playlistHistoryClient: PlaylistHistoryClient {
    get { self[PlaylistHistoryClient.self] }
    set { self[PlaylistHistoryClient.self] = newValue }
  }
}
