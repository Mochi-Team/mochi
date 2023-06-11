//
//  Live.swift
//  
//
//  Created ErrorErrorError on 5/26/23.
//  Copyright © 2023. All rights reserved.
//

import AVFoundation
import Dependencies
import Foundation

extension VideoPlayerClient: DependencyKey {
    public static let liveValue: Self = {
        let player = AVQueuePlayer()
        return Self(
            load: { @MainActor link in
                player.replaceCurrentItem(with: .init(url: link))
            },
            play: { @MainActor in
                player.play()
            },
            pause: { @MainActor in
                player.pause()
            },
            seek: { @MainActor progress in
                if let duration = player.currentItem?.duration {
                    player.seek(to: .init(seconds: duration.seconds * progress, preferredTimescale: 1))
                }
            },
            volume: { @MainActor amount in },
            clear: { @MainActor in
                player.removeAllItems()
            },
            player: player
        )
    }()
}
