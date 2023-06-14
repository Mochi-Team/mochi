//
//  PlayerFeature.swift
//
//
//  Created by ErrorErrorError on 6/10/23.
//
//

import Architecture
import AVKit
import Foundation
import SwiftUI

public enum PlayerFeature: Feature {
    public struct State: FeatureState {
        public var status: AVPlayer.Status
        public var rate: Float
        public var progress: CMTime
        public var duration: CMTime
        public var gravity: AVLayerVideoGravity
        @BindingState
        public var pipState: PIPState

        public init(
            status: AVPlayer.Status = .unknown,
            rate: Float = 0.0,
            progress: CMTime = .zero,
            duration: CMTime = .zero,
            gravity: AVLayerVideoGravity = .resizeAspect,
            pipState: PIPState = .init()
        ) {
            self.status = status
            self.rate = rate
            self.progress = progress
            self.duration = duration
            self.gravity = gravity
            self.pipState = pipState
        }

        public struct PIPState: Equatable, Sendable {
            public var enabled: Bool
            public var status: PIPStatus
            public var isActive: Bool
            public var isSupported: Bool
            public var isPossible: Bool

            public init(
                enabled: Bool = false,
                status: PIPStatus = .didStop,
                isActive: Bool = false,
                isSupported: Bool = false,
                isPossible: Bool = false
            ) {
                self.enabled = enabled
                self.status = status
                self.isActive = isActive
                self.isSupported = isSupported
                self.isPossible = isPossible
            }
        }
    }

    public enum Action: FeatureAction {
        public enum ViewAction: SendableAction, BindableAction {
            case didAppear
            case didTapGoForwards
            case didTapGoBackwards
            case didTogglePlayButton
            case didTogglePictureInPicture
            case didStartedSeeking
            case didFinishedSeekingTo(CGFloat)
            case binding(BindingAction<State>)
        }

        public enum InternalAction: SendableAction {
            case rate(Float)
            case progress(CMTime)
            case duration(CMTime)
        }

        public enum DelegateAction: SendableAction {}

        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)
    }

    public struct Reducer: FeatureReducer {
        public typealias State = PlayerFeature.State
        public typealias Action = PlayerFeature.Action

        public init() {}

        @Dependency(\.playerClient)
        var playerClient

        public var body: some ComposableArchitecture.Reducer<State, Action> {
            Case(/Action.view) {
                BindingReducer()
            }

            Reduce { state, action in
                switch action {
                case .view(.didAppear):
                    return .merge(
                        .run { send in
                            for await rate in playerClient.player.valueStream(\.rate) {
                                await send(.internal(.rate(rate)))
                            }
                        },
                        .run { send in
                            for await time in playerClient.player.periodicTimeStream() {
                                await send(.internal(.progress(time)))
                            }
                        },
                        .run { send in
                            for await time in playerClient.player.valueStream(\.currentItem?.duration) {
                                await send(.internal(.duration(time ?? .zero)))
                            }
                        }
                    )

                case .view(.didTogglePlayButton):
                    let isPlaying = state.rate != .zero
                    return .run { _ in
                        await isPlaying ? playerClient.pause() : playerClient.play()
                    }

                case .view(.didStartedSeeking):
                    return .run { _ in
                        await playerClient.pause()
                    }

                case .view(.didTogglePictureInPicture):
                    state.pipState.enabled.toggle()

                case .view(.didTapGoBackwards):
                    let newProgress = max(0, state.progress.seconds - 15)
                    let duration = state.duration.seconds
                    state.progress = .init(seconds: newProgress, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                    return .run { _ in
                        await playerClient.seek(newProgress / duration)
                    }

                case .view(.didTapGoForwards):
                    let newProgress = min(state.duration.seconds, state.progress.seconds + 15)
                    let duration = state.duration.seconds
                    state.progress = .init(seconds: newProgress, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                    return .run { _ in
                        await playerClient.seek(newProgress / duration)
                    }

                case let .view(.didFinishedSeekingTo(progress)):
                    state.progress = .init(seconds: progress * state.duration.seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                    return .run { _ in
                        await playerClient.seek(progress)
                        await playerClient.play()
                    }

                case .view(.binding(\.$pipState.isActive)):
                    if state.pipState.enabled, !state.pipState.isActive {
                        state.pipState.enabled = false
                    }

                case .view(.binding):
                    break

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

    @MainActor
    public struct View: FeatureView {
        public let store: StoreOf<PlayerFeature.Reducer>

        public nonisolated init(store: StoreOf<PlayerFeature.Reducer>) {
            self.store = store
        }

        @Dependency(\.playerClient.player)
        var player

        private struct PlayerViewState: Sendable, Equatable {
            let gravity: AVLayerVideoGravity
            let enablePIP: Bool

            init(_ state: State) {
                self.gravity = state.gravity
                self.enablePIP = state.pipState.enabled
            }
        }

        @MainActor
        public var body: some SwiftUI.View {
            WithViewStore(store, observe: PlayerViewState.init) { viewStore in
                PlayerView(
                    player: player,
                    gravity: viewStore.gravity,
                    enablePIP: viewStore.enablePIP
                )
                .pictureInPictureStatus { status in
                    viewStore.send(.view(.binding(.set(\.$pipState.status, status))))
                }
                .pictureInPictureIsActive { active in
                    viewStore.send(.view(.binding(.set(\.$pipState.isActive, active))))
                }
                .pictureInPictureIsPossible { possible in
                    viewStore.send(.view(.binding(.set(\.$pipState.isPossible, possible))))
                }
                .pictureInPictureIsSupported { supported in
                    viewStore.send(.view(.binding(.set(\.$pipState.isSupported, supported))))
                }
                .onAppear {
                    viewStore.send(.view(.didAppear))
                }
            }
        }
    }
}
