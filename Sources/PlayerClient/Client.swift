//
//  Client.swift
//
//
//  Created ErrorErrorError on 5/26/23.
//  Copyright © 2023. All rights reserved.
//

@preconcurrency
import AVFoundation
import Dependencies
import Foundation
import XCTestDynamicOverlay

// MARK: - PlayerClient

public struct PlayerClient: Sendable {
    public let load: @Sendable (VideoCompositionItem) async throws -> Void
    public let setRate: @Sendable (Float) async -> Void
    public let play: @Sendable () async -> Void
    public let pause: @Sendable () async -> Void
    public let seek: @Sendable (_ progress: Double) async -> Void
    public let volume: @Sendable (_ amount: Double) async -> Void
    public let clear: @Sendable () async -> Void
    let player: AVPlayer
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
        clear: unimplemented(),
        player: unimplemented()
    )
}

public extension DependencyValues {
    var playerClient: PlayerClient {
        get { self[PlayerClient.self] }
        set { self[PlayerClient.self] = newValue }
    }
}
