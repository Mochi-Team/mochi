//
//  AVPlayer+AsyncStream.swift
//  
//
//  Created by ErrorErrorError on 6/10/23.
//  
//

import AVKit
import Foundation

extension AVPlayer {
    func valueStream<Value>(_ keyPath: KeyPath<AVPlayer, Value>) -> AsyncStream<Value> {
        .init(Value.self) { continuation in
            let observation = self.observe(keyPath) { _, _ in
                continuation.yield(self[keyPath: keyPath])
            }

            continuation.onTermination = { _ in
                observation.invalidate()
            }
        }
    }

    func periodicTimeStream(
        interval: CMTime = .init(
            seconds: 0.5,
            preferredTimescale: CMTimeScale(NSEC_PER_SEC)
        )
    ) -> AsyncStream<CMTime> {
        .init { continuation in
            let observer = self.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
                continuation.yield(time)
            }
            continuation.onTermination = { [weak self] _ in
                self?.removeTimeObserver(observer)
            }
        }
    }
}

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
        totalDuration > .zero ? currentDuration / totalDuration : .zero
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
