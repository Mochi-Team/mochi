//
//  VideoPlayerFeature+Player.swift
//  
//
//  Created by ErrorErrorError on 6/10/23.
//  
//

import AVKit
import ComposableArchitecture
import Foundation

public struct PlayerReducer: Reducer {
    public struct State: Equatable, Sendable {
        public var status: AVPlayer.Status
        public var rate: Float
        public var progress: CMTime
        public var duration: CMTime

        public init(
            status: AVPlayer.Status = .unknown,
            rate: Float = 0.0,
            progress: CMTime = .zero,
            duration: CMTime = .zero
        ) {
            self.status = status
            self.rate = rate
            self.progress = progress
            self.duration = duration
        }
    }

    public enum Action: Equatable, Sendable {
        public enum ViewAction: Equatable, Sendable {
            case didTapGoForwards
            case didTapGoBackwards
            case didTogglePlayButton
            case didStartedSeeking
            case didFinishedSeekingTo(CGFloat)
        }

        public enum InternalAction: Equatable, Sendable {
            case rate(Float)
            case progress(CMTime)
            case duration(CMTime)
        }

        case initialize
        case view(ViewAction)
        case `internal`(InternalAction)
    }

    @Dependency(\.videoPlayerClient)
    var videoPlayerClient

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .initialize:
                return .merge(
                    .run { send in
                        for await rate in videoPlayerClient.player.valueStream(\.rate) {
                            await send(.internal(.rate(rate)))
                        }
                    },
                    .run { send in
                        for await time in videoPlayerClient.player.periodicTimeStream() {
                            await send(.internal(.progress(time)))
                        }
                    },
                    .run { send in
                        for await time in videoPlayerClient.player.valueStream(\.currentItem?.duration) {
                            await send(.internal(.duration(time ?? .zero)))
                        }
                    }
                )

            case .view(.didTogglePlayButton):
                let isPlaying = state.rate != .zero
                return .run { _ in
                    await isPlaying ? videoPlayerClient.pause() : videoPlayerClient.play()
                }

            case .view(.didStartedSeeking):
                return .run { _ in
                    await videoPlayerClient.pause()
                }

            case .view(.didTapGoBackwards):
                let newProgress = max(0, state.progress.seconds - 15)
                let duration = state.duration.seconds
                state.progress = .init(seconds: newProgress, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                return .run { _ in
                    await videoPlayerClient.seek(newProgress / duration)
                }

            case .view(.didTapGoForwards):
                let newProgress = min(state.duration.seconds, state.progress.seconds + 15)
                let duration = state.duration.seconds
                state.progress = .init(seconds: newProgress, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                return .run { _ in
                    await videoPlayerClient.seek(newProgress / duration)
                }

            case let .view(.didFinishedSeekingTo(progress)):
                state.progress = .init(seconds: progress * state.duration.seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                return .run { _ in
                    await videoPlayerClient.seek(progress)
                    await videoPlayerClient.play()
                }

            case let .internal(.rate(rate)):
                state.rate = rate

            case let .internal(.progress(progress)):
                state.progress = progress

            case let .internal(.duration(duration)):
                state.duration = duration
            }
            return .none
        }
    }
}
