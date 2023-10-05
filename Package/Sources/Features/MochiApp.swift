//
//  MochiApp.swift
//  
//
//  Created by ErrorErrorError on 10/4/23.
//  
//

import Foundation

struct MochiApp: Product, Target {
    var name: String {
        "App"
    }

    var path: String? {
        "Sources/Features/\(self.name)"
    }

    var dependencies: any Dependencies {
        Architecture()
        Discover()
        Repos()
        Search()
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
