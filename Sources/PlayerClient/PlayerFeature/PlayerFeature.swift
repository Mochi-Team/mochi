//
//  PlayerFeature.swift
//
//
//  Created by ErrorErrorError on 6/10/23.
//
//

import Architecture
@preconcurrency
import AVKit
import Foundation
import SwiftUI

// swiftlint:disable type_body_length
public enum PlayerFeature: Feature {
    public struct State: FeatureState {
        public var status: AVPlayer.Status
        public var timeControlStatus: AVPlayer.TimeControlStatus
        public var rate: Float
        public var progress: CMTime
        public var duration: CMTime
        public var gravity: AVLayerVideoGravity
        public var pipState: PIPState
        public var isPlaybackBufferEmpty: Bool
        public var isPlaybackBufferFull: Bool
        public var isPlaybackLikelyToKeepUp: Bool

        public var selectedSubtitle: AVMediaSelectionOption?
        public var subtitles: AVMediaSelectionGroup?

        public init(
            status: AVPlayer.Status = .unknown,
            timeControlStatus: AVPlayer.TimeControlStatus = .waitingToPlayAtSpecifiedRate,
            rate: Float = 0.0,
            progress: CMTime = .zero,
            duration: CMTime = .zero,
            gravity: AVLayerVideoGravity = .resizeAspect,
            pipState: PIPState = .init(),
            isPlaybackBufferEmpty: Bool = true,
            isPlaybackBufferFull: Bool = false,
            isPlaybackLikelyToKeepUp: Bool = false
        ) {
            self.status = status
            self.timeControlStatus = timeControlStatus
            self.rate = rate
            self.progress = progress
            self.duration = duration
            self.gravity = gravity
            self.pipState = pipState
            self.isPlaybackBufferEmpty = isPlaybackBufferEmpty
            self.isPlaybackBufferFull = isPlaybackBufferFull
            self.isPlaybackLikelyToKeepUp = isPlaybackLikelyToKeepUp
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
        public enum ViewAction: SendableAction {
            case didAppear
            case didTapGoForwards
            case didTapGoBackwards
            case didTogglePlayButton
            case didTogglePictureInPicture
            case didStartedSeeking
            case didFinishedSeekingTo(CGFloat)
            case didTapSubtitle(for: AVMediaSelectionGroup, AVMediaSelectionOption?)
            case didSelectRate(Float)
            case didSetPiPStatus(PIPStatus)
            case didSetPiPActive(Bool)
            case didSetPiPPossible(Bool)
            case didSetPiPSupported(Bool)

        }

        public enum InternalAction: SendableAction {
            case status(AVPlayer.Status)
            case rate(Float)
            case progress(CMTime)
            case duration(CMTime)
            case timeControlStatus(AVPlayer.TimeControlStatus)
            case playbackBufferFull(Bool)
            case playbackBufferEmpty(Bool)
            case playbackLikelyToKeepUp(Bool)
            case subtitles(AVMediaSelectionGroup?)
            case selectedSubtitle(AVMediaSelectionOption?)
        }

        public enum DelegateAction: SendableAction {
            case didStartedSeeking
            case didFinishedSeekingTo(CGFloat)
            case didTapGoForwards
            case didTapGoBackwards
            case didTogglePlayButton
            case didTapClosePiP
        }

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

        enum Cancellables: Hashable {
            case initialize
        }

        public var body: some ComposableArchitecture.Reducer<State, Action> {
//            Case(/Action.view) {
//                BindingReducer()
//            }

            Reduce { state, action in
                switch action {
                case .view(.didAppear):
                    return .run { send in
                        await withTaskCancellation(id: Cancellables.initialize) {
                            await withTaskGroup(of: Void.self) { group in
                                group.addTask {
                                    for await rate in playerClient.player.valueStream(\.rate) {
                                        await send(.internal(.rate(rate)))
                                    }
                                }

                                group.addTask {
                                    for await time in playerClient.player.periodicTimeStream() {
                                        await send(.internal(.progress(time)))
                                    }
                                }

                                group.addTask {
                                    for await time in playerClient.player.valueStream(\.currentItem?.duration) {
                                        await send(.internal(.duration(time ?? .zero)))
                                    }
                                }

                                group.addTask {
                                    for await status in playerClient.player.valueStream(\.status) {
                                        await send(.internal(.status(status)))
                                    }
                                }

                                group.addTask {
                                    for await status in playerClient.player.valueStream(\.timeControlStatus) {
                                        await send(.internal(.timeControlStatus(status)))
                                    }
                                }

                                group.addTask {
                                    for await empty in playerClient.player.valueStream(\.currentItem?.isPlaybackBufferEmpty) {
                                        await send(.internal(.playbackBufferEmpty(empty ?? true)))
                                    }
                                }

                                group.addTask {
                                    for await full in playerClient.player.valueStream(\.currentItem?.isPlaybackBufferFull) {
                                        await send(.internal(.playbackBufferFull(full ?? false)))
                                    }
                                }

                                group.addTask {
                                    for await canKeepUp in playerClient.player.valueStream(\.currentItem?.isPlaybackLikelyToKeepUp) {
                                        await send(.internal(.playbackLikelyToKeepUp(canKeepUp ?? false)))
                                    }
                                }

                                group.addTask {
                                    for await selection in playerClient.player.valueStream(\.currentItem?.currentMediaSelection) {
                                        if let selection,
                                           let group = playerClient.player.currentItem?.asset.mediaSelectionGroup(forMediaCharacteristic: .legible),
                                           let option = selection.selectedMediaOption(in: group) {
                                            await send(.internal(.selectedSubtitle(option)))
                                        } else {
                                            await send(.internal(.selectedSubtitle(nil)))
                                        }
                                    }
                                }

                                group.addTask {
                                    for await asset in playerClient.player.valueStream(\.currentItem?.asset) {
                                        if let asset, let group = asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
                                            await send(.internal(.subtitles(group)))
                                        } else {
                                            await send(.internal(.subtitles(nil)))
                                        }
                                    }
                                }
                            }
                        }
                    }

                case .view(.didTogglePlayButton):
                    let isPlaying = state.rate != .zero
                    return .merge(
                        .send(.delegate(.didTogglePlayButton)),
                        .run { _ in
                            await isPlaying ? playerClient.pause() : playerClient.play()
                        }
                    )

                case .view(.didTogglePictureInPicture):
                    state.pipState.enabled.toggle()

                case .view(.didTapGoBackwards):
                    let newProgress = max(0, state.progress.seconds - 15)
                    let duration = state.duration.seconds
                    state.progress = .init(seconds: newProgress, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                    return .merge(
                        .send(.delegate(.didTapGoBackwards)),
                        .run { _ in
                            await playerClient.seek(newProgress / duration)
                        }
                    )

                case .view(.didTapGoForwards):
                    let newProgress = min(state.duration.seconds, state.progress.seconds + 15)
                    let duration = state.duration.seconds
                    state.progress = .init(seconds: newProgress, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                    return .merge(
                        .send(.delegate(.didTapGoBackwards)),
                        .run { _ in
                            await playerClient.seek(newProgress / duration)
                        }
                    )

                case .view(.didStartedSeeking):
                    return .merge(
                        .send(.delegate(.didStartedSeeking)),
                        .run { _ in
                            await playerClient.pause()
                        }
                    )

                case let .view(.didFinishedSeekingTo(progress)):
                    state.progress = .init(seconds: progress * state.duration.seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                    return .merge(
                        .send(.delegate(.didFinishedSeekingTo(progress))),
                        .run { _ in
                            await playerClient.seek(progress)
                            await playerClient.play()
                        }
                    )

                case let .view(.didSelectRate(rate)):
                    return .run { _ in
                        await playerClient.setRate(rate)
                    }

                case let .view(.didTapSubtitle(group, option)):
                    return .run { _ in
                        await playerClient.player.currentItem?.select(option, in: group)
                    }

                case let .view(.didSetPiPActive(active)):
                    state.pipState.isActive = active

                case let .view(.didSetPiPStatus(status)):
                    state.pipState.status = status

                case let .view(.didSetPiPPossible(possible)):
                    state.pipState.isPossible = possible

                case let .view(.didSetPiPSupported(supported)):
                    state.pipState.isSupported = supported

                case let .internal(.status(status)):
                    state.status = status

                case let .internal(.timeControlStatus(status)):
                    state.timeControlStatus = status

                case let .internal(.rate(rate)):
                    state.rate = rate

                case let .internal(.progress(progress)):
                    state.progress = progress

                case let .internal(.duration(duration)):
                    state.duration = duration

                case let .internal(.playbackBufferEmpty(empty)):
                    state.isPlaybackBufferEmpty = empty

                case let .internal(.playbackBufferFull(full)):
                    state.isPlaybackBufferFull = full

                case let .internal(.playbackLikelyToKeepUp(keepUp)):
                    state.isPlaybackLikelyToKeepUp = keepUp

                case let .internal(.subtitles(subtitles)):
                    state.subtitles = subtitles

                case let .internal(.selectedSubtitle(option)):
                    state.selectedSubtitle = option

                case .delegate:
                    break
                }
                return .none
            }
            .onChange(of: \.pipState.status) { oldValue, newValue in
                // This signifies that the X button was pressed, so should dismiss
                Reduce { _, _ in
                    if oldValue != .restoreUI && newValue == .willStop {
                        return .send(.delegate(.didTapClosePiP))
                    }
                    return .none
                }
            }
            .onChange(of: \.pipState.isActive) { oldValue, newValue in
                Reduce { state, _ in
                    if oldValue && !newValue {
                        state.pipState.enabled = false
                    }
                    return .none
                }
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
                    viewStore.send(.view(.didSetPiPStatus(status)))
                }
                .pictureInPictureIsActive { active in
                    viewStore.send(.view(.didSetPiPActive(active)))
                }
                .pictureInPictureIsPossible { possible in
                    viewStore.send(.view(.didSetPiPPossible(possible)))
                }
                .pictureInPictureIsSupported { supported in
                    viewStore.send(.view(.didSetPiPSupported(supported)))
                }
                .onAppear {
                    viewStore.send(.view(.didAppear))
                }
            }
        }
    }
}

public extension PlayerFeature.State {
    var isBuffering: Bool {
        !isPlaybackBufferFull && isPlaybackBufferEmpty || !isPlaybackLikelyToKeepUp
    }
}
