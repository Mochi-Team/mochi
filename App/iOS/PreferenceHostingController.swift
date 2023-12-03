//
//  HostingController.swift
//  mochi
//
//  Created by ErrorErrorError on 6/27/23.
//
//

#if canImport(UIKit)
import Foundation
import SwiftUI
import UIKit
import ViewComponents

final class PreferenceHostingController<Root: View>: UIHostingController<BoxedView<Root>>, OpaquePreferenceHostingController {
    override var prefersHomeIndicatorAutoHidden: Bool { _homeIndicatorAutoHidden }

    var _homeIndicatorAutoHidden = false {
        didSet {
            setNeedsUpdateOfHomeIndicatorAutoHidden()
        }
    }

    private let box: Box

    init(rootView: @escaping () -> Root) {
        self.box = .init()
        super.init(rootView: .init(box: box, content: rootView))
        box.object = self
    }

    @available(*, unavailable)
    dynamic required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct BoxedView<Content: View>: View {
    let box: Box

    init(box: Box, content: @escaping () -> Content) {
        self.content = content
        self.box = box
    }

    let content: () -> Content

    var body: some View {
        content()
            .onPreferenceChange(HomeIndicatorAutoHiddenPreferenceKey.self) { isHidden in
                box.object?._homeIndicatorAutoHidden = isHidden
            }
    }
}

final class Box {
    weak var object: OpaquePreferenceHostingController?
}

@MainActor
protocol OpaquePreferenceProperties {
    var _homeIndicatorAutoHidden: Bool { get set }
}

@MainActor
protocol OpaquePreferenceHostingController: OpaquePreferenceProperties, UIViewController {}
#endif
