//
//  AVPlayer+Extension.swift
//
//
//  Created by ErrorErrorError on 6/10/23.
//
//

import AVKit
import Foundation

extension AVPlayerItem {
    var bufferProgress: Double {
        totalDuration > .zero ? currentBufferDuration / totalDuration : .zero
    }

    var currentBufferDuration: Double {
        loadedTimeRanges.first?.timeRangeValue.end.seconds ?? .zero
    }

    var currentDuration: Double {
        currentTime().seconds
    }

    var playProgress: Double {
        totalDuration != .zero ? currentDuration / totalDuration : .zero
    }

    var totalDuration: Double {
        asset.duration.seconds
    }
}

// MARK: AVPlayer + Extension

extension AVPlayer {
    var bufferProgress: Double {
        currentItem?.bufferProgress ?? .zero
    }

    var currentBufferDuration: Double {
        currentItem?.currentBufferDuration ?? .zero
    }

    var currentDuration: Double {
        currentItem?.currentDuration ?? .zero
    }

    var playProgress: Double {
        currentItem?.playProgress ?? .zero
    }

    var totalDuration: Double {
        currentItem?.totalDuration ?? .zero
    }

    convenience init(asset: AVURLAsset) {
        self.init(playerItem: AVPlayerItem(asset: asset))
    }
}

extension AVPlayerItem {
    func mediaSelectionGroup(for characteristic: AVMediaCharacteristic, name: String) -> MediaSelectionGroup? {
        asset.mediaSelectionGroup(forMediaCharacteristic: characteristic).flatMap { group in
            .init(
                name: name,
                selected: currentMediaSelection.selectedMediaOption(in: group).flatMap { .init($0) },
                group
            )
        }
    }
}

// MARK: - AVPlayerItem.Status + CustomStringConvertible, CustomDebugStringConvertible

extension AVPlayerItem.Status: CustomStringConvertible, CustomDebugStringConvertible {
    public var debugDescription: String {
        description
    }

    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .readyToPlay:
            return "readyToPlay"
        case .failed:
            return "failed"
        @unknown default:
            return "default-unknown"
        }
    }
}

// MARK: - AVPlayer.Status + CustomStringConvertible, CustomDebugStringConvertible

extension AVPlayer.Status: CustomStringConvertible, CustomDebugStringConvertible {
    public var debugDescription: String {
        description
    }

    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .readyToPlay:
            return "readyToPlay"
        case .failed:
            return "failed"
        @unknown default:
            return "default-unknown"
        }
    }
}

// MARK: - AVPlayer.TimeControlStatus + CustomStringConvertible, CustomDebugStringConvertible

extension AVPlayer.TimeControlStatus: CustomStringConvertible, CustomDebugStringConvertible {
    public var debugDescription: String {
        description
    }

    public var description: String {
        switch self {
        case .paused:
            return "paused"
        case .waitingToPlayAtSpecifiedRate:
            return "waitingToPlayAtSpecifiedRate"
        case .playing:
            return "playing"
        @unknown default:
            return "default-unknown"
        }
    }
}
