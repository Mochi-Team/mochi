//
//  PlayerRoutePickerView.swift
//
//
//  Created by ErrorErrorError on 6/17/23.
//
//

import AVKit
import Foundation
import SwiftUI
import ViewComponents

public struct PlayerRoutePickerView: PlatformAgnosticViewRepresentable {
    public init() {}

    public func makePlatformView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView(frame: .zero)
        view.delegate = context.coordinator

        #if os(iOS)
        view.prioritizesVideoDevices = true
        view.tintColor = .white
        #elseif os(macOS)
        view.isRoutePickerButtonBordered = false
        view.setRoutePickerButtonColor(.white, for: .normal)
        #endif
        return view
    }

    public func updatePlatformView(_: AVRoutePickerView, context _: Context) {}

    public func makeCoordinator() -> Coordinator {
        .init()
    }

    public class Coordinator: NSObject, AVRoutePickerViewDelegate {}
}
