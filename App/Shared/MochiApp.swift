//
//  MochiApp.swift
//  mochi
//
//  Created by ErrorErrorError on 3/24/23.
//
//

import App
import SwiftUI

@main
struct MochiApp: App {
    var body: some Scene {
        WindowGroup {
            AppFeature.View(
                store: .init(
                    initialState: .home(),
                    reducer: AppFeature.Reducer()
                )
            )
        }
    }
}
