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

#if !os(iOS)
@main
struct MochiApp: App {
    var body: some Scene {
        WindowGroup {
            AppFeature.View(
                store: appDelegate.store
            )
        }
    }
}
#endif
