//
//  PlayerView.swift
//
//
//  Created by ErrorErrorError on 5/31/23.
//
//

import AVFoundation
import AVKit
import Combine
import Foundation
import SwiftUI
import ViewComponents

// MARK: - PiPStatus

public enum PiPStatus: Equatable, Sendable {
    case willStart
    case didStart
    case willStop
    case didStop
    case restoreUI
    case failed(Error)

    public var isInPiP: Bool {
        self == .willStart || self == .didStart
    }

    public static func == (lhs: PiPStatus, rhs: PiPStatus) -> Bool {
        switch (lhs, rhs) {
        case (.willStart, .willStart),
             (.didStart, .didStart),
             (.willStop, .willStop),
             (.didStop, .didStop),
             (.restoreUI, .restoreUI):
            return true
        case let (.failed(lhsError), .failed(rhsError)):
            return _isEqual(lhsError, rhsError)
        default:
            return false
        }
    }
}

// MARK: - PlayerView

struct PlayerView: PlatformAgnosticViewRepresentable {
    private let player: AVPlayer

    private let gravity: AVLayerVideoGravity
    private let enablePIP: Bool

    private var pipIsSupportedCallback: (@Sendable (Bool) -> Void)?
    private var pipIsActiveCallback: (@Sendable (Bool) -> Void)?
    private var pipIsPossibleCallback: (@Sendable (Bool) -> Void)?
    private var pipStatusCallback: (@Sendable (PiPStatus) -> Void)?

    init(
        player: AVPlayer,
        gravity: AVLayerVideoGravity = .resizeAspect,
        enablePIP: Bool
    ) {
        self.player = player
        self.gravity = gravity
        self.enablePIP = enablePIP
    }

    func makeCoordinator() -> Coordinator {
        .init(self)
    }

    func makePlatformView(context: Context) -> AVPlayerView {
        let view = AVPlayerView(player: player)
        context.coordinator.initialize(view)
        return view
    }

    func updatePlatformView(
        _ platformView: AVPlayerView,
        context: Context
    ) {
        if gravity != platformView.videoGravity {
            platformView.videoGravity = gravity
        }

        guard let pipController = context.coordinator.controller else {
            return
        }

        if enablePIP {
            if !pipController.isPictureInPictureActive, pipController.isPictureInPicturePossible {
                pipController.startPictureInPicture()
            }
        } else {
            if pipController.isPictureInPictureActive {
                pipController.stopPictureInPicture()
            }
        }
    }
}

extension PlayerView {
    func pictureInPictureIsActive(_ callback: @escaping @Sendable (Bool) -> Void) -> Self {
        var view = self
        view.pipIsActiveCallback = callback
        return view
    }

    func pictureInPictureIsPossible(_ callback: @escaping @Sendable (Bool) -> Void) -> Self {
        var view = self
        view.pipIsPossibleCallback = callback
        return view
    }

    func pictureInPictureIsSupported(_ callback: @escaping @Sendable (Bool) -> Void) -> Self {
        var view = self
        view.pipIsSupportedCallback = callback
        return view
    }

    func pictureInPictureStatus(_ callback: @escaping @Sendable (PiPStatus) -> Void) -> Self {
        var view = self
        view.pipStatusCallback = callback
        return view
    }
}

// MARK: PlayerView.Coordinator

extension PlayerView {
    final class Coordinator: NSObject {
        let videoPlayer: PlayerView
        var controller: AVPictureInPictureController?
        var cancellables = Set<AnyCancellable>()

        init(_ videoPlayer: PlayerView) {
            self.videoPlayer = videoPlayer
            super.init()
        }

        func initialize(_ view: AVPlayerView) {
            guard controller == nil, AVPictureInPictureController.isPictureInPictureSupported() else {
                return
            }

            let controller = AVPictureInPictureController(contentSource: .init(playerLayer: view.playerLayer))
            self.controller = controller

            controller.delegate = self
            controller.canStartPictureInPictureAutomaticallyFromInline = true

            DispatchQueue.main.async { [weak self] in
                self?.videoPlayer.pipIsSupportedCallback?(true)
            }

            controller.publisher(for: \.isPictureInPictureActive)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isActive in
                    self?.videoPlayer.pipIsActiveCallback?(isActive)
                }
                .store(in: &cancellables)

            controller.publisher(for: \.isPictureInPicturePossible)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isPossible in
                    self?.videoPlayer.pipIsPossibleCallback?(isPossible)
                }
                .store(in: &cancellables)
        }
    }
}

// MARK: - PlayerView.Coordinator + AVPictureInPictureControllerDelegate

extension PlayerView.Coordinator: AVPictureInPictureControllerDelegate {
    public func pictureInPictureControllerWillStartPictureInPicture(_: AVPictureInPictureController) {
        DispatchQueue.main.async { [weak self] in
            self?.videoPlayer.pipStatusCallback?(.willStart)
        }
    }

    public func pictureInPictureControllerDidStartPictureInPicture(_: AVPictureInPictureController) {
        DispatchQueue.main.async { [weak self] in
            self?.videoPlayer.pipStatusCallback?(.didStart)
        }
    }

    public func pictureInPictureControllerWillStopPictureInPicture(_: AVPictureInPictureController) {
        DispatchQueue.main.async { [weak self] in
            self?.videoPlayer.pipStatusCallback?(.willStop)
        }
    }

    public func pictureInPictureControllerDidStopPictureInPicture(_: AVPictureInPictureController) {
        DispatchQueue.main.async { [weak self] in
            self?.videoPlayer.pipStatusCallback?(.didStop)
        }
    }

    public func pictureInPictureController(
        _: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.videoPlayer.pipStatusCallback?(.restoreUI)
        }
        completionHandler(true)
    }

    public func pictureInPictureController(
        _: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.videoPlayer.pipStatusCallback?(.failed(error))
        }
    }
}

// MARK: - AVPlayerView

final class AVPlayerView: PlatformView {
    // swiftlint:disable force_cast
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    #if os(iOS)
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    #elseif os(macOS)
    override func makeBackingLayer() -> CALayer { AVPlayerLayer() }
    #endif

    var videoGravity: AVLayerVideoGravity {
        get { playerLayer.videoGravity }
        set { playerLayer.videoGravity = newValue }
    }

    init(player: AVPlayer) {
        super.init(frame: .zero)
        #if os(macOS)
        wantsLayer = true
        #endif
        self.player = player
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func _isEqual(_ lhs: Any, _ rhs: Any) -> Bool {
    (lhs as? any Equatable)?.isEqual(other: rhs) ?? false
}

private extension Equatable {
    func isEqual(other: Any) -> Bool {
        self == other as? Self
    }
}
