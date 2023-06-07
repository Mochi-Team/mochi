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

public struct VideoPlayerClient: Sendable {
    // TODO: Add client interface types
//    let status: @Sendable () -> AsyncStream<Status>
//    let load: @Sendable () async throws -> Void
//    let play: @Sendable () async throws -> Void
//    let resume: @Sendable () async throws -> Void
//    let pause: @Sendable () async throws -> Void
//    let seek: @Sendable (_ progress: Double) async throws -> Void
//    let volume: @Sendable (_ amount: Double) async throws -> Void
//    let reset: @Sendable () async throws -> Void
    public let player: AVPlayer
}

extension VideoPlayerClient: TestDependencyKey {
    public static let testValue = Self(
        player: unimplemented()
    )
}

extension DependencyValues {
    public var videoPlayerClient: VideoPlayerClient {
        get { self[VideoPlayerClient.self] }
        set { self[VideoPlayerClient.self] = newValue }
    }
}
