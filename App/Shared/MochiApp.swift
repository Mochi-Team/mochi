//
//  MochiApp.swift
//  mochi
//
//  Created by ErrorErrorError on 3/24/23.
//
//

import App
import ComposableArchitecture
import Settings
import SwiftUI
import VideoPlayer

#if os(macOS)
@main
struct MochiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    var body: some Scene {
        WindowGroup {
            AppFeature.View(
                store: appDelegate.store
            )
            .themeable()
            .frame(
                minWidth: 800,
                maxWidth: .infinity,
                minHeight: 625,
                maxHeight: .infinity
            )
        }
        .windowStyle(.titleBar)
        .commands {
            SidebarCommands()
            ToolbarCommands()

            CommandGroup(replacing: .newItem) {}
        }

        Settings {
            SettingsFeature.View(
                store: appDelegate.store.scope(
                    state: \.settings,
                    action: { .internal(.settings($0)) }
                )
            )
            .themeable()
        }
    }
}
#endif
