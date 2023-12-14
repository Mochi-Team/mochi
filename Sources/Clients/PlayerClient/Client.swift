//
//  Client.swift
//
//
//  Created ErrorErrorError on 5/26/23.
//  Copyright © 2023. All rights reserved.
//

import AVFoundation
import Dependencies
import Foundation
import XCTestDynamicOverlay

// MARK: - PlayerClient

public struct PlayerClient: Sendable {
  public var load: @Sendable (VideoCompositionItem) async throws -> Void
  public var setRate: @Sendable (Float) async -> Void
  public var play: @Sendable () async -> Void
  public var pause: @Sendable () async -> Void
  public var seek: @Sendable (_ progress: Double) async -> Void
  public var volume: @Sendable (_ amount: Double) async -> Void
  public var setOption: @Sendable (_ option: MediaSelectionOption?, _ in: MediaSelectionGroup) async -> Void
  public var clear: @Sendable () async -> Void
  public var get: @Sendable () -> Status
  public var observe: @Sendable () -> AsyncStream<Status>

  // TODO: Create Custom AVPlayer and AVPlayerItems and each holds
  //  an item. Internally it should retrieve the contents when possible, rather than
  //  having an internal model doing it.
  public var player: @Sendable () -> AVPlayer
}

// MARK: TestDependencyKey

extension PlayerClient: TestDependencyKey {
  public static let testValue = Self(
    load: unimplemented(),
    setRate: unimplemented(),
    play: unimplemented(),
    pause: unimplemented(),
    seek: unimplemented(),
    volume: unimplemented(),
    setOption: unimplemented(),
    clear: unimplemented(),
    get: unimplemented(),
    observe: unimplemented(),
    player: unimplemented()
  )
}

extension DependencyValues {
  public var playerClient: PlayerClient {
    get { self[PlayerClient.self] }
    set { self[PlayerClient.self] = newValue }
  }
}
