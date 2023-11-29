//
//  ToolbarAccessory.swift
//
//
//  Created by ErrorErrorError on 11/28/23.
//  
//

#if os(macOS)
import Foundation
import SwiftUI

public extension View {
    func toolbarAccesssory<Content: View>(id: String, _ content: @escaping () -> Content) -> some View {
        self.modifier(ToolbarAccessoryViewModifier(id, content))
    }
}

private struct ToolbarAccessoryViewModifier<Accessory: View>: ViewModifier {
    let id: String
    let accessory: () -> Accessory

    init(_ id: String, _ accessory: @escaping () -> Accessory) {
        self.id = id
        self.accessory = accessory
    }

    func body(content: Content) -> some View {
        if #available(macOS 13, *) {
            content.toolbar { ToolbarItem(placement: .accessoryBar(id: id), content: accessory) }
        } else {
            content
                .onAppear {
                    guard let window else {
                        return
                    }

                    if !window.titlebarAccessoryViewControllers.contains(where: { $0.identifier?.rawValue == _internalTitleBarItemId }) {
                        // No accessory found with this identifier, so create one and add it
                        let vc = NSTitlebarAccessoryViewController()
                        vc.view = NSHostingView(
                            rootView: accessory()
                                .font(.footnote.weight(.semibold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 8)
                        )
                        vc.identifier = .init(rawValue: _internalTitleBarItemId)
                        window.addTitlebarAccessoryViewController(vc)
                    }
                }
                .onDisappear {
                    guard let window else {
                        return
                    }

                    if let index = window.titlebarAccessoryViewControllers.firstIndex(where: { $0.identifier?.rawValue == _internalTitleBarItemId }) {
                        window.removeTitlebarAccessoryViewController(at: index)
                    }
                }
        }
    }

    private var window: NSWindow? { NSApplication.shared.mainWindow }
    private var _internalTitleBarItemId: String { "__internal-\(id)" }
}

#endif
