//
//  VideoPlayerFeature+Player.swift
//  
//
//  Created by ErrorErrorError on 6/10/23.
//  
//

import ComposableArchitecture
import Foundation

public struct PlayerReducer: Reducer {
    public struct State: Equatable, Sendable {
        public var isPlaying: Bool
        public var progress: Double

        public init(
            isPlaying: Bool = false,
            progress: Double = 0.0
        ) {
            self.isPlaying = isPlaying
            self.progress = progress
        }
    }

    public enum Action: Equatable, Sendable {
        case didTogglePlayButton
    }

    @Dependency(\.videoPlayerClient)
    var videoPlayerClient

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .didTogglePlayButton:
                state.isPlaying.toggle()
                let isPlaying = state.isPlaying
                return .run { _ in
                    await isPlaying ? videoPlayerClient.pause() : videoPlayerClient.play()
                }
            }
            return .none
        }
    }
}
