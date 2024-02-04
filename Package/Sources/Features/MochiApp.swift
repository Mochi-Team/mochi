//
//  MochiApp.swift
//
//
//  Created by ErrorErrorError on 10/4/23.
//
//

import Foundation

struct MochiApp: _Feature {
    var name: String { "App" }

    var dependencies: any Dependencies {
        Architecture()
        Discover()
        Repos()
        Settings()
        SharedModels()
        Styling()
        UserSettingsClient()
        VideoPlayer()
        ViewComponents()
        ComposableArchitecture()
        NukeUI()
    }
}
