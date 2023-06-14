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
import Dependencies
import Foundation
import MediaPlayer

extension PlayerClient: DependencyKey {
    public static let liveValue: Self = {
        let player = AVQueuePlayer()

        player.allowsExternalPlayback = true
        player.automaticallyWaitsToMinimizeStalling = true
        player.preventsDisplaySleepDuringVideoPlayback = true
        player.actionAtItemEnd = .pause

        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(
            .playback,
            mode: .moviePlayback,
            policy: .longFormVideo
        )
        #endif

        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget { _ in
            if player.rate == 0.0 {
                player.play()
                return .success
            }

            return .commandFailed
        }

        commandCenter.pauseCommand.addTarget { _ in
            if player.rate > 0 {
                player.pause()
                return .success
            }

            return .commandFailed
        }

        commandCenter.changePlaybackPositionCommand.addTarget { event in
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

        commandCenter.skipForwardCommand.addTarget { event in
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

        commandCenter.skipBackwardCommand.addTarget { event in
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

        return Self(
            load: { @MainActor link in
                player.replaceCurrentItem(with: .init(url: link))
                #if os(iOS)
                try? session.setActive(true)
                #endif
            },
            play: { @MainActor in
                player.play()
            },
            pause: { @MainActor in
                player.pause()
            },
            seek: { @MainActor progress in
                if let duration = player.currentItem?.duration, duration.seconds > .zero {
                    player.seek(
                        to: .init(
                            seconds: duration.seconds * progress,
                            preferredTimescale: 1
                        ),
                        toleranceBefore: .zero,
                        toleranceAfter: .zero
                    )
                }
            },
            volume: { @MainActor volume in
                player.volume = .init(volume)
            },
            clear: { @MainActor in
                player.pause()
                player.removeAllItems()
                #if os(iOS)
                try? session.setActive(false, options: .notifyOthersOnDeactivation)
                #endif
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
                #if os(macOS)
                MPNowPlayingInfoCenter.default().playbackState = .unknown
                #endif
            },
            player: player
        )
    }()
}
