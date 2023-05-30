//
//  Models.swift
//  
//
//  Created by ErrorErrorError on 5/26/23.
//  
//

import Foundation

public extension VideoPlayerClient {
    enum Status: Equatable, Sendable {
        case idle
        case loading
        case loaded(duration: Double)
        case playback(state: Playback)
        case finished
        case error
    }
}

public extension VideoPlayerClient.Status {
    enum Playback: Equatable, Sendable {
        case buffering
        case playing
        case paused
    }
}
