//
//  PlayerView.swift
//  
//
//  Created by ErrorErrorError on 5/31/23.
//  
//

import AVFoundation
import AVKit
import Foundation
import SwiftUI
import ViewComponents

struct VideoPlayer: PlatformAgnosticViewRepresentable {

    private let player: AVPlayer

    @Binding
    private var gravity: AVLayerVideoGravity

    @Binding
    private var pipActive: Bool

    init(
        player: AVPlayer,
        gravity: Binding<AVLayerVideoGravity> = .constant(.resizeAspect),
        pipActive: Binding<Bool> = .constant(false)
    ) {
        self.player = player
        self._gravity = gravity
        self._pipActive = pipActive
    }

    func makeCoordinator() -> Coordinator {
        .init(self)
    }

    func makePlatformView(context: Context) -> PlayerView {
        let view = PlayerView(player: player)
        context.coordinator.updateController(view)
        return view
    }

    func updatePlatformView(
        _ platformView: PlayerView,
        context: Context
    ) {
//        if platformView.videoGravity != gravity {
//            platformView.videoGravity = gravity
//        }

//        guard let pipController = context.coordinator.controller else {
//            return
//        }

//        if pipActive, !pipController.isPictureInPictureActive {
//            pipController.startPictureInPicture()
//        } else if !pipActive, pipController.isPictureInPictureActive {
//            pipController.stopPictureInPicture()
//        }
    }
}

extension VideoPlayer {
    final class Coordinator: NSObject {
        var videoPlayer: VideoPlayer
        var controller: AVPictureInPictureController?

        init(_ videoPlayer: VideoPlayer) {
            self.videoPlayer = videoPlayer
            super.init()
        }

        func updateController(_ view: PlayerView) {
            guard controller == nil else {
                return
            }

            controller = .init(playerLayer: view.playerLayer)
            controller?.delegate = self
        }
    }
}

extension VideoPlayer.Coordinator: AVPictureInPictureControllerDelegate {
    public func pictureInPictureControllerWillStartPictureInPicture(_: AVPictureInPictureController) {
//        videoPlayer.onPictureInPictureStatusChangedCallback?(.willStart)
    }

    public func pictureInPictureControllerDidStartPictureInPicture(_: AVPictureInPictureController) {
//        videoPlayer.onPictureInPictureStatusChangedCallback?(.didStart)
    }

    public func pictureInPictureControllerWillStopPictureInPicture(_: AVPictureInPictureController) {
//        videoPlayer.onPictureInPictureStatusChangedCallback?(.willStop)
    }

    public func pictureInPictureControllerDidStopPictureInPicture(_: AVPictureInPictureController) {
//        videoPlayer.onPictureInPictureStatusChangedCallback?(.didStop)
    }

    public func pictureInPictureController(
        _: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
//        videoPlayer.onPictureInPictureStatusChangedCallback?(.restoreUI)
        completionHandler(true)
    }

    public func pictureInPictureController(
        _: AVPictureInPictureController,
        failedToStartPictureInPictureWithError _: Error
    ) {
//        videoPlayer.onPictureInPictureStatusChangedCallback?(.failedToStart)
    }
}

final class PlayerView: PlatformView {
    // swiftlint:disable force_cast
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    #if os(iOS)
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    #else
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
