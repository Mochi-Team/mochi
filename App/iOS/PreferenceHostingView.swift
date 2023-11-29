//
//  PreferenceHostingView.swift
//  Mochi
//
//  Created by ErrorErrorError on 11/28/23.
//  
//  Source: https://gist.github.com/Amzd/01e1f69ecbc4c82c8586dcd292b1d30d

import Foundation
import SwiftUI

#if canImport(UIKit)
@MainActor
struct PreferenceHostingView<Content: View>: UIViewControllerRepresentable {
    init(content: @escaping () -> Content) {
        _ = UIViewController.swizzle()
        self.content = content
    }

    let content: () -> Content

    func makeUIViewController(context: Context) -> PreferenceHostingController<Content> {
        PreferenceHostingController(rootView: content)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}

extension UIViewController {
    static func swizzle() {
        Swizzle(UIViewController.self) {
            #selector(getter: childForHomeIndicatorAutoHidden) => #selector(__swizzledChildForHomeIndicatorAutoHidden)
        }
    }

    @objc func __swizzledChildForHomeIndicatorAutoHidden() -> UIViewController? {
        if self is OpaquePreferenceHostingController {
            return nil
        } else {
            return search()
        }
    }

    private func search() -> OpaquePreferenceHostingController? {
        if let result = children.compactMap({ $0 as? OpaquePreferenceHostingController }).first {
            return result
        }

        for child in children {
            if let result = child.search() {
                return result
            }
        }

        return nil
    }
}
#endif

// Move to utils?
struct Swizzle {
    @discardableResult
    init(
        _ type: AnyClass,
        @SwizzleSelectorsBuilder builder: () -> [SwizzleReplacer]
    ) {
        builder().forEach { $0(type) }
    }
}

struct SwizzleReplacer {
    let original: Selector
    let swizzled: Selector

    func callAsFunction(_ type: AnyClass) {
        guard let originalMethod = class_getInstanceMethod(type, original),
              let swizzledMethod = class_getInstanceMethod(type, swizzled) else {
            return
        }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

@resultBuilder
enum SwizzleSelectorsBuilder {
    typealias Component = SwizzleReplacer

    static func buildBlock(_ components: Component...) -> [Component] {
        components
    }
}

infix operator =>

extension Selector {
    static func => (original: Selector, swizzled: Selector) -> SwizzleReplacer {
        .init(original: original, swizzled: swizzled)
    }
}
