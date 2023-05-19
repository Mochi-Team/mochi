//
//  MochiApp.swift
//  mochi
//
//  Created by ErrorErrorError on 3/24/23.
//
//

import App
import ComposableArchitecture
import SwiftUI

@main
struct MochiApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    var body: some Scene {
        WindowGroup {
            AppFeature.View(
                store: appDelegate.store
            )
        }
    }
}
