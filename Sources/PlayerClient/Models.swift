//
//  Models.swift
//
//
//  Created by ErrorErrorError on 5/26/23.
//
//

import Foundation

// MARK: - PlayerClient.Status

public extension PlayerClient {
    enum Status: Equatable, Sendable {
        case idle
        case loading
        case loaded(duration: Double)
        case playback(state: Playback)
        case finished
        case error
    }
}

// MARK: - PlayerClient.Status.Playback

public extension PlayerClient.Status {
    enum Playback: Equatable, Sendable {
        case buffering
        case playing
        case paused
    }
}
