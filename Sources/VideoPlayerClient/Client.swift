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
//    let status: @Sendable () -> AsyncStream<Status>
    public let load: @Sendable (URL) async throws -> Void
    public let play: @Sendable () async -> Void
    public let pause: @Sendable () async -> Void
    public let seek: @Sendable (_ progress: Double) async -> Void
    public let volume: @Sendable (_ amount: Double) async -> Void
    public let clear: @Sendable () async -> Void
    public let player: AVPlayer
}

extension VideoPlayerClient: TestDependencyKey {
    public static let testValue = Self(
        load: unimplemented(),
        play: unimplemented(),
        pause: unimplemented(),
        seek: unimplemented(),
        volume: unimplemented(),
        clear: unimplemented(),
        player: unimplemented()
    )
}

extension DependencyValues {
    public var videoPlayerClient: VideoPlayerClient {
        get { self[VideoPlayerClient.self] }
        set { self[VideoPlayerClient.self] = newValue }
    }
}
