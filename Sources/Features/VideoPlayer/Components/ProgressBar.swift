//
//  ProgressBar.swift
//  
//
//  Created by ErrorErrorError on 11/22/23.
//  
//

import Architecture
import ComposableArchitecture
import Foundation
import PlayerClient
import SwiftUI
import ViewComponents

struct ProgressBar: View {
    let store: Store<PlayerClient.Status.Playback?, VideoPlayerFeature.Action>
    @ObservedObject
    private var viewState: ViewStore<PlayerClient.Status.Playback?, VideoPlayerFeature.Action.ViewAction>

    @SwiftUI.State
    private var dragProgress: Double = 0
    @SwiftUI.State
    private var isDragging = false

    @Dependency(\.dateComponentsFormatter)
    var formatter

    init(store: Store<PlayerClient.Status.Playback?, VideoPlayerFeature.Action>) {
        self.store = store
        self.viewState = .init(store, observe: \.`self`)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(.thinMaterial)
                            .preferredColorScheme(.dark)
                        Color.white
                            .frame(
                                width: proxy.size.width * dragProgress,
                                height: proxy.size.height,
                                alignment: .leading
                            )
                    }
                    .frame(
                        width: proxy.size.width,
                        height: isDragging ? 12 : 8
                    )
                    .clipShape(Capsule(style: .continuous))
                }
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height
                )
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !isDragging {
                                dragProgress = progress
                                isDragging = true
                            }
                            dragProgress = max(0, min(1.0, value.location.x / proxy.size.width))
                            viewState.send(.didSkipTo(time: dragProgress))
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
                .animation(.spring(response: 0.3), value: isDragging)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 24)

            Group {
                if canUseControls {
                    @Dependency(\.dateComponentsFormatter)
                    var formatter

                    Text(progressDisplayTime) +
                        Text(" / ") +
                    Text(formatter.playbackTimestamp(viewState.state?.totalDuration ?? 0) ?? Self.defaultZeroTime)
                } else {
                    Text("\(Self.defaultEmptyTime) / \(Self.defaultEmptyTime)")
                }
            }
            .font(.caption.monospacedDigit())
        }
        .disabled(!canUseControls)
        .onAppear {
            dragProgress = viewState.state?.progress ?? 0
        }
        // Stop initial bounce
        .animation(.linear(duration: 0), value: dragProgress)
    }

    private var progressDisplayTime: String {
        if canUseControls {
            if isDragging {
                let time = (dragProgress ?? .zero) * (viewState.state?.totalDuration ?? .zero)
                return formatter.playbackTimestamp(time) ?? Self.defaultZeroTime
            } else {
                return formatter.playbackTimestamp(viewState.state?.duration ?? .zero) ?? Self.defaultZeroTime
            }
        } else {
            return Self.defaultEmptyTime
        }
    }
}

private extension ProgressBar {
    private static let defaultEmptyTime = "--:--"
    private static let defaultZeroTime = "00:00"

    var progress: Double {
        if canUseControls {
            min(1.0, max(0, (viewState.state?.progress ?? 0)))
        } else {
            .zero
        }
    }

    var canUseControls: Bool {
        if let totalDuration = viewState.state?.totalDuration {
            return !totalDuration.isNaN && !totalDuration.isInfinite && !totalDuration.isZero
        }
        return false
    }
}
