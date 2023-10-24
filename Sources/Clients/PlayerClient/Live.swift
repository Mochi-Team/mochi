//
//  Live.swift
//
//
//  Created ErrorErrorError on 5/26/23.
//  Copyright © 2023. All rights reserved.
//

import AVFAudio
import AVFoundation
import AVKit
import Combine
import Dependencies
import Foundation
import MediaPlayer
import Nuke

// MARK: - PlayerClient + DependencyKey

extension PlayerClient: DependencyKey {
    public static let liveValue: Self = {
        let impl = InternalPlayer()

        return Self(
            load: { @MainActor composition in try await impl.load(composition) },
            setRate: { @MainActor rate in impl.setRate(rate) },
            play: { @MainActor in await impl.play() },
            pause: { @MainActor in await impl.pause() },
            seek: { @MainActor progress in await impl.seek(to: progress) },
            volume: { @MainActor volume in await impl.volume(to: volume) },
            clear: { @MainActor in await impl.clear() },
            status: { @MainActor in impl.status() },
            player: impl.player
        )
    }()
}

// MARK: - InternalPlayer

private class InternalPlayer {
    let player: AVQueuePlayer

    #if os(iOS)
    private let session: AVAudioSession
    #endif

    private let nowPlaying: NowPlaying

    init() {
        self.player = .init()
        self.nowPlaying = .init(player: player)

        #if os(iOS)
        self.session = AVAudioSession.sharedInstance()
        try? session.setCategory(
            .playback,
            mode: .moviePlayback,
            policy: .longFormVideo
        )
        #endif

        player.allowsExternalPlayback = true
        player.automaticallyWaitsToMinimizeStalling = true
        player.preventsDisplaySleepDuringVideoPlayback = true
        player.actionAtItemEnd = .pause
        player.appliesMediaSelectionCriteriaAutomatically = true

        initCommandCenter()
    }

    @MainActor
    func load(_ item: PlayerClient.VideoCompositionItem) async throws {
        let playerItem = PlayerItem(item)
        player.replaceCurrentItem(with: playerItem)

        #if os(iOS)
        try? session.setActive(true)
        #endif

        nowPlaying.update(with: item.metadata)
    }

    @MainActor
    func setRate(_ rate: Float) {
        player.rate = rate
    }

    @MainActor
    func play() async {
        player.play()
    }

    @MainActor
    func pause() async {
        player.pause()
    }

    @MainActor
    func seek(to progress: Double) async {
        if let duration = player.currentItem?.duration, duration.seconds > .zero {
            await player.seek(
                to: .init(
                    seconds: duration.seconds * progress,
                    preferredTimescale: CMTimeScale(NSEC_PER_SEC)
                ),
                toleranceBefore: .zero,
                toleranceAfter: .zero
            )
        }
    }

    @MainActor
    func volume(to volume: Double) async {
        player.volume = .init(volume)
    }

    @MainActor
    func clear() async {
        player.pause()
        player.removeAllItems()
        #if os(iOS)
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
        #endif
        nowPlaying.clear()
    }

    @MainActor
    func status() -> AsyncStream<PlayerClient.Status> {
        .finished
    }
}

extension InternalPlayer {
    private func initCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [unowned self] _ in
            if player.rate == 0.0 {
                player.play()
                return .success
            }

            return .commandFailed
        }

        commandCenter.pauseCommand.addTarget { [unowned self] _ in
            if player.rate != 0 {
                player.pause()
                return .success
            }

            return .commandFailed
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [unowned self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }

            if player.totalDuration > 0.0 {
                let time = CMTime(seconds: event.positionTime, preferredTimescale: 1)
                player.seek(to: time)
                return .success
            }

            return .commandFailed
        }

        commandCenter.skipForwardCommand.addTarget { [unowned self] event in
            guard let event = event as? MPSkipIntervalCommandEvent else {
                return .commandFailed
            }

            if player.totalDuration > 0.0 {
                let time = CMTime(
                    seconds: min(player.currentDuration + event.interval, player.totalDuration),
                    preferredTimescale: 1
                )
                player.seek(to: time)
                return .success
            }

            return .commandFailed
        }

        commandCenter.skipBackwardCommand.addTarget { [unowned self] event in
            guard let event = event as? MPSkipIntervalCommandEvent else {
                return .commandFailed
            }

            if player.totalDuration > 0.0 {
                let time = CMTime(
                    seconds: max(player.currentDuration - event.interval, 0.0),
                    preferredTimescale: 1
                )
                player.seek(to: time)
                return .success
            }

            return .commandFailed
        }
    }
}

// MARK: - NowPlaying

private class NowPlaying {
    let player: AVPlayer

    private let infoCenter: MPNowPlayingInfoCenter
    private var cancellables = Set<AnyCancellable>()
    private var timeObserver: Any?

    init(player: AVPlayer) {
        self.player = player
        self.infoCenter = .default()
        initPlayerObservables()
    }

    private func initPlayerObservables() {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: .init(
                seconds: 1.0,
                preferredTimescale: 1
            ),
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updatePlayerStatsIfPresent()
            }
        }

        player.publisher(for: \.currentItem)
            .sink { [weak self] item in
                if item == nil {
                    DispatchQueue.main.async {
                        self?.clear()
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func updatePlayerStatsIfPresent() {
        var info = infoCenter.nowPlayingInfo
        info?[MPMediaItemPropertyPlaybackDuration] = player.currentItem?.totalDuration ?? player.totalDuration
        info?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentItem?.currentDuration ?? player.currentDuration
        info?[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        infoCenter.nowPlayingInfo = info
    }

    @MainActor
    func update(with metadata: PlayerClient.SourceMetadata) {
        var info = infoCenter.nowPlayingInfo ?? [:]

        info[MPMediaItemPropertyTitle] = metadata.title
        info[MPMediaItemPropertyAlbumTitle] = metadata.subtitle
        info[MPMediaItemPropertyArtist] = metadata.author

        if let imageURL = metadata.artworkImage {
            if let image = ImagePipeline.shared.cache.cachedImage(for: .init(url: imageURL))?.image {
                let artwork = MPMediaItemArtwork(boundsSize: image.size) { size in
                    #if os(macOS)
                    let copy = (image.copy() as? NSImage).unsafelyUnwrapped
                    copy.size = size
                    #else
                    let copy = image.resize(to: size) ?? .init()
                    #endif
                    return copy
                }
                info[MPMediaItemPropertyArtwork] = artwork
            } else {
                info[MPMediaItemPropertyArtwork] = nil
            }
        }

        infoCenter.nowPlayingInfo = info

        updatePlayerStatsIfPresent()

        #if os(macOS)
        #endif
    }

    @MainActor
    func clear() {
        infoCenter.nowPlayingInfo = nil
        #if os(macOS)
        infoCenter.playbackState = .unknown
        #endif
    }
}

#if os(iOS)
extension UIImage {
    func resize(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: CGPoint.zero, size: size))
        if let resizedImage = UIGraphicsGetImageFromCurrentImageContext() {
            return resizedImage
        }
        return nil
    }
}
#endif
