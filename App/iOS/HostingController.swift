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

final class HostingController<Content: View>: UIHostingController<Content>, OpaqueController {
    override var prefersHomeIndicatorAutoHidden: Bool { _homeIndicatorAutoHidden }

    var _homeIndicatorAutoHidden = false {
        didSet {
            setNeedsUpdateOfHomeIndicatorAutoHidden()
        }
    }

    private let box: Box

    init<InnerView: View>(rootView: InnerView) where Content == BoxedView<InnerView> {
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

    init(box: Box, content: @autoclosure @escaping () -> Content) {
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
    weak var object: OpaqueController?
}

@MainActor
protocol OpaqueController: AnyObject {
    var _homeIndicatorAutoHidden: Bool { get set }
}
#endif
