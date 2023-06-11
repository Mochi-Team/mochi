//
//  VideoPlayer.swift
//  
//
//  Created by ErrorErrorError on 6/10/23.
//  
//

import AVKit
import Foundation
import SwiftUI

@MainActor
struct VideoPlayer: View {
    @StateObject
    private var viewModel: ViewModel

    init(player: AVPlayer) {
        self._viewModel = .init(wrappedValue: .init(player: player))
    }

    @MainActor
    var body: some View {
        ZStack {
            PlayerView(player: viewModel.player)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .ignoresSafeArea(.all, edges: .all)
                .contentShape(Rectangle())
                .onTapGesture {
                }

            if viewModel.showControls {
                toolsOverlay
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.black
                .edgesIgnoringSafeArea(.all)
                .ignoresSafeArea(.all, edges: .all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
        .onAppear {
        }
        .preferredColorScheme(.dark)
    }
}

extension VideoPlayer {
    @MainActor
    var toolsOverlay: some View {
        VStack {
            topBar
            Spacer()
            bottomBar
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .center) {
            controlsBar
                .edgesIgnoringSafeArea(.all)
                .ignoresSafeArea()
        }
        .background {
            Color.black
                .opacity(0.2)
                .ignoresSafeArea()
                .edgesIgnoringSafeArea(.all)
                .allowsHitTesting(false)
        }
    }

    @MainActor
    var topBar: some View {
        HStack(alignment: .top, spacing: 8) {
            Button {
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
            } label: {
                Image(systemName: "airplayvideo")
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
                    .rotationEffect(.degrees(90))
            }
            .buttonStyle(.plain)
        }
        .font(.body.weight(.medium))
    }

    @MainActor
    var controlsBar: some View {
        HStack(spacing: 24) {
            Spacer()

            Button {
            } label: {
                Image(systemName: "gobackward")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
            } label: {
                Image(systemName: "goforward")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    @MainActor
    var bottomBar: some View {
        ProgressBar(player: viewModel.player) {
        } didFinishedSeekingTo: { seek in
        }
        .frame(maxWidth: .infinity)
    }
}

extension VideoPlayer {
    struct ProgressBar: View {
        let player: AVPlayer
        var aboutToSeek: (() -> Void)?
        var didFinishedSeekingTo: (CGFloat) -> Void

        @SwiftUI.State
        private var canUseControls = false

        @SwiftUI.State
        private var progress = CGFloat.zero

        @SwiftUI.State
        private var isDragging = false

        @SwiftUI.State
        private var timeObserverToken: Any?

        var body: some View {
            VStack(alignment: .leading) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        ZStack(alignment: .leading) {
                            Color.gray.opacity(0.35)
                            Color.white
                                .frame(
                                    width: proxy.size.width * progress,
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
                                    isDragging = true
                                    aboutToSeek?()
                                }

                                let locationX = value.location.x
                                let percentage = locationX / proxy.size.width
                                progress = max(0, min(1.0, percentage))
                            }
                            .onEnded { _ in
                                isDragging = false
                                didFinishedSeekingTo(progress)
                            }
                    )
                    .animation(.spring(response: 0.3), value: isDragging)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 24)
            }
            .onReceive(player.publisher(for: \.currentItem)) { item in
                if let item {
                    let timeScale = CMTimeScale(NSEC_PER_SEC)
                    let time = CMTime(seconds: 0.5, preferredTimescale: timeScale)
                    timeObserverToken = player.addPeriodicTimeObserver(forInterval: time, queue: .main) { time in
                        if !isDragging {
                            progress = time.seconds / max(item.duration.seconds, 1)
                        }
                    }
                } else {
                    progress = .zero
                }
            }
            .onReceive(player.publisher(for: \.status)) { status in
                switch status {
                case .readyToPlay:
                    canUseControls = true
                    progress = .zero
                case .unknown, .failed:
                    canUseControls = false
                    progress = .zero
                @unknown default:
                    canUseControls = false
                    progress = .zero
                }
            }
            .onDisappear {
                if let timeObserverToken {
                    player.removeTimeObserver(timeObserverToken)
                    self.timeObserverToken = nil
                }
            }
            .disabled(!canUseControls)
        }
    }
}

extension VideoPlayer {
    @MainActor
    private class ViewModel: ObservableObject {
        let player: AVPlayer

        @MainActor
        @Published
        var isPlaying = false

        @MainActor
        @Published
        var progress = 0.0

        @MainActor
        @Published
        var duration = 0.0

        @MainActor
        @Published
        var showControls = true

        init(player: AVPlayer) {
            self.player = player
        }
    }
}
