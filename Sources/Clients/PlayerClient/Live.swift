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
      load: { composition in try await impl.load(composition) },
      setRate: { rate in await impl.setRate(rate) },
      play: { await impl.play() },
      pause: { await impl.pause() },
      seek: { progress in await impl.seek(to: progress) },
      volume: { volume in await impl.volume(to: volume) },
      setOption: { option, group in await impl.setOption(option, in: group) },
      clear: { await impl.clear() },
      get: { impl.status() },
      observe: { impl.observe() },
      player: { impl.player }
    )
  }()
}

// MARK: - InternalPlayer

private class InternalPlayer {
  private enum ResolvableTime {
    case waiting(Double)
    case resolved

    func waiting() -> Double? {
      switch self {
      case let .waiting(waiting):
        waiting
      case .resolved:
        nil
      }
    }

    mutating func resolve() -> Double? {
      switch self {
      case let .waiting(double):
        self = .resolved
        return double
      case .resolved:
        self = .resolved
        return nil
      }
    }
  }

  let player: AVQueuePlayer
  let subject = CurrentValueSubject<PlayerClient.Status, Never>(.idle)

  private let resolveProgress = LockIsolated<ResolvableTime>(.resolved)

  #if os(iOS)
  private let session: AVAudioSession
  #endif

  private let nowPlaying: NowPlaying
  private var timerObserver: Any?
  private var cancellables = Set<AnyCancellable>()

  init() {
    self.player = .init()
    self.nowPlaying = .init(statusPublisher: subject)

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
    initObservers()
  }

  deinit {
    if let timerObserver {
      player.removeTimeObserver(timerObserver)
    }
  }

  @MainActor
  func load(_ item: PlayerClient.VideoCompositionItem) throws {
    resolveProgress.setValue(.resolved)

    let playerItem = PlayerItem(item)
    player.replaceCurrentItem(with: playerItem)
    if let progress = item.progress {
      let time = CMTime(seconds: progress * player.totalDuration, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
      player.seek(to: time)
    }

    #if os(iOS)
    try session.setActive(true)
    #endif

    nowPlaying.update(with: item.metadata)
  }

  @MainActor
  func setRate(_ rate: Float) {
    player.rate = rate
  }

  // TODO: Fix issue with options not setting
  @MainActor
  func setOption(_ option: MediaSelectionOption?, in group: MediaSelectionGroup) {
    player.currentItem?.select(option?._ref, in: group._ref)
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
    resolveProgress.setValue(.waiting(progress))
    updatePlayback()

    if let duration = player.currentItem?.duration, duration.seconds > .zero {
      if await player.seek(
        to: .init(
          seconds: duration.seconds * progress,
          preferredTimescale: CMTimeScale(NSEC_PER_SEC)
        ),
        toleranceBefore: .zero,
        toleranceAfter: .zero
      ) {
        _ = resolveProgress.withValue { $0.resolve() }
      }
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
    resolveProgress.setValue(.resolved)
    #if os(iOS)
    try? session.setActive(false, options: .notifyOthersOnDeactivation)
    #endif
    nowPlaying.clear()
  }

  func status() -> PlayerClient.Status {
    subject.value
  }

  func observe() -> AsyncStream<PlayerClient.Status> {
    subject.values.eraseToStream()
  }
}

extension InternalPlayer {
  private func initCommandCenter() {
    let commandCenter = MPRemoteCommandCenter.shared()

    commandCenter.playCommand.addTarget { [weak self] _ in
      guard let self else {
        return .commandFailed
      }

      if player.rate == 0.0 {
        player.play()
        return .success
      }

      return .commandFailed
    }

    commandCenter.pauseCommand.addTarget { [weak self] _ in
      guard let self else {
        return .commandFailed
      }
      if player.rate != 0 {
        player.pause()
        return .success
      }

      return .commandFailed
    }

    commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
      guard let self else {
        return .commandFailed
      }
      guard let event = event as? MPChangePlaybackPositionCommandEvent else {
        return .commandFailed
      }

      if player.totalDuration > 0.0 {
        let time = CMTime(
          seconds: event.positionTime,
          preferredTimescale: CMTimeScale(NSEC_PER_SEC)
        )
        player.seek(to: time)
        return .success
      }

      return .commandFailed
    }

    commandCenter.skipForwardCommand.addTarget { [weak self] event in
      guard let self else {
        return .commandFailed
      }

      guard let event = event as? MPSkipIntervalCommandEvent else {
        return .commandFailed
      }

      if player.totalDuration > 0.0 {
        let time = CMTime(
          seconds: min(player.currentDuration + event.interval, player.totalDuration),
          preferredTimescale: CMTimeScale(NSEC_PER_SEC)
        )
        player.seek(to: time)
        return .success
      }

      return .commandFailed
    }

    commandCenter.skipBackwardCommand.addTarget { [weak self] event in
      guard let self else {
        return .commandFailed
      }
      guard let event = event as? MPSkipIntervalCommandEvent else {
        return .commandFailed
      }

      if player.totalDuration > 0.0 {
        let time = CMTime(
          seconds: max(player.currentDuration - event.interval, 0.0),
          preferredTimescale: CMTimeScale(NSEC_PER_SEC)
        )
        player.seek(to: time)
        return .success
      }

      return .commandFailed
    }
  }
}

extension InternalPlayer {
  private func initObservers() {
    timerObserver = player.addPeriodicTimeObserver(
      forInterval: .init(
        seconds: 1.0,
        preferredTimescale: CMTimeScale(NSEC_PER_SEC)
      ),
      queue: .main
    ) { [weak self] _ in
      self?.updatePlayback()
    }

    player.publisher(for: \.rate)
      .sink { [weak self] _ in
        self?.updatePlayback()
      }
      .store(in: &cancellables)

    player.publisher(for: \.currentItem?.duration)
      .sink { [weak self] _ in
        self?.updatePlayback()
      }
      .store(in: &cancellables)

    player.publisher(for: \.status)
      .sink { [weak self] _ in
        self?.updatePlayback()
      }
      .store(in: &cancellables)

    player.publisher(for: \.timeControlStatus)
      .sink { [weak self] _ in
        self?.updatePlayback()
      }
      .store(in: &cancellables)

    player.publisher(for: \.currentItem?.isPlaybackBufferEmpty)
      .sink { [weak self] _ in
        self?.updatePlayback()
      }
      .store(in: &cancellables)

    player.publisher(for: \.currentItem?.isPlaybackBufferFull)
      .sink { [weak self] _ in
        self?.updatePlayback()
      }
      .store(in: &cancellables)

    player.publisher(for: \.currentItem?.isPlaybackLikelyToKeepUp)
      .sink { [weak self] _ in
        self?.updatePlayback()
      }
      .store(in: &cancellables)

    player.publisher(for: \.currentItem?.currentMediaSelection)
      .sink { [weak self] _ in
        self?.updatePlayback()
      }
      .store(in: &cancellables)

    player.publisher(for: \.currentItem?.asset)
      .sink { [weak self] _ in
        self?.updatePlayback()
      }
      .store(in: &cancellables)
  }

  private func updatePlayback() {
    let updatedStatus: PlayerClient.Status

    if player.status == .failed {
      updatedStatus = .error
    } else {
      if let item = player.currentItem, item.totalDuration != .zero {
        let isBufferEmpty = item.isPlaybackBufferEmpty
        let isBufferFull = item.isPlaybackBufferFull
        let canPlaybackKeepUp = item.isPlaybackLikelyToKeepUp
        let isBuffering = isBufferFull ? false : (isBufferEmpty || !canPlaybackKeepUp)
        updatedStatus = .playback(
          .init(
            state: isBuffering ? .buffering : player.rate == .zero ? .paused : .playing,
            duration: resolveProgress.value.waiting().flatMap { $0 * item.totalDuration } ?? item.currentDuration,
            buffered: item.bufferProgress,
            totalDuration: item.totalDuration,
            selections: [
              item.mediaSelectionGroup(for: .legible, name: "Subtitle"),
              item.mediaSelectionGroup(for: .audible, name: "Audio"),
              item.mediaSelectionGroup(for: .visual, name: "Servers")
            ]
            .compactMap { $0 }
          )
        )
      } else if player.currentItem != nil {
        updatedStatus = .loading
      } else {
        updatedStatus = .idle
      }
    }

    if updatedStatus != subject.value {
      subject.send(updatedStatus)
    }
  }
}

// MARK: - NowPlaying

private class NowPlaying {
  let statusPublisher: any Publisher<PlayerClient.Status, Never>
  let nowPlaying = LockIsolated<PlayerClient.SourceMetadata?>(nil)

  private let infoCenter: MPNowPlayingInfoCenter
  private var cancellables = Set<AnyCancellable>()
  private var timeObserver: Any?

  init(statusPublisher: any Publisher<PlayerClient.Status, Never>) {
    self.statusPublisher = statusPublisher
    self.infoCenter = .default()
    initPlayerObservables()
  }

  private func initPlayerObservables() {
    statusPublisher
      .sink { [weak self] value in
        self?.updatePlayerStatus(value)
      }
      .store(in: &cancellables)
  }

  private func updatePlayerStatus(_ status: PlayerClient.Status) {
    var info = infoCenter.nowPlayingInfo
    info?[MPMediaItemPropertyPlaybackDuration] = status.playback?.totalDuration
    info?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = status.playback?.duration
    info?[MPNowPlayingInfoPropertyPlaybackRate] = status.playback?.state == .playing ? 1.0 : 0.0
    infoCenter.nowPlayingInfo = info

    #if os(macOS)
    switch status {
    case .idle:
      infoCenter.playbackState = .stopped
    case .loading:
      infoCenter.playbackState = .stopped
    case let .playback(playback):
      switch playback.state {
      case .buffering, .paused:
        infoCenter.playbackState = .paused
      case .playing:
        infoCenter.playbackState = .playing
      }
    case .error:
      infoCenter.playbackState = .unknown
    }
    #endif
  }

  @MainActor
  func update(with metadata: PlayerClient.SourceMetadata) {
    nowPlaying.setValue(metadata)
    var info = infoCenter.nowPlayingInfo ?? [:]

    info[MPMediaItemPropertyTitle] = metadata.title
    info[MPMediaItemPropertyAlbumTitle] = metadata.subtitle
    info[MPMediaItemPropertyArtist] = metadata.author

    if let imageURL = metadata.artworkImage {
      // TODO: Download url image if not in cache
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
  }

  @MainActor
  func clear() {
    nowPlaying.setValue(nil)
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
