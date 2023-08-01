//
//  HostingController.swift
//  mochi
//
//  Created by ErrorErrorError on 6/27/23.
//
//

#if os(iOS)
import Foundation
import SwiftUI
import UIKit
import ViewComponents

final class HostingController: UIHostingController<AnyView> {
    override var prefersHomeIndicatorAutoHidden: Bool { _homeIndicatorAutoHidden }

    private var _homeIndicatorAutoHidden = false {
        didSet {
            setNeedsUpdateOfHomeIndicatorAutoHidden()
        }
    }

    private let box: Box

    init(rootView: some View) {
        let box = Box()
        self.box = box
        super.init(
            rootView:
            .init(
                rootView
                    .onPreferenceChange(HomeIndicatorAutoHiddenPreferenceKey.self) { isHidden in
                        box.object?._homeIndicatorAutoHidden = isHidden
                    }
            )
        )
        box.object = self
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class Box {
    weak var object: HostingController?
}

#endif
