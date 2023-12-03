//
//  PreferenceHostingView.swift
//  Mochi
//
//  Created by ErrorErrorError on 11/28/23.
//  
//

import Architecture
import Foundation
import LoggerClient
import SwiftUI
import ViewComponents

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

extension PreferenceHostingView {
    func injectPreference() -> some View {
        self.modifier(PreferenceModifier())
    }
}

private struct PreferenceModifier: ViewModifier, OpaquePreferenceProperties {
    @State
    var _homeIndicatorAutoHidden = false

    func body(content: Content) -> some View {
        if #available(iOS 16, *) {
            content
                .persistentSystemOverlays(_homeIndicatorAutoHidden ? .hidden : .visible)
                .onPreferenceChange(HomeIndicatorAutoHiddenPreferenceKey.self) { preference in
                    _homeIndicatorAutoHidden = preference
                }
        } else {
            // Use swizzle's version
            content
        }
    }
}

extension UIViewController {
    static func swizzle() {
        if #unavailable(iOS 16) {
            Swizzle(UIViewController.self) {
                #selector(getter: childForHomeIndicatorAutoHidden) => #selector(swizzled_childForHomeIndicatorAutoHidden)
            }
        }
    }

    @objc func swizzled_childForHomeIndicatorAutoHidden() -> UIViewController? {
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
