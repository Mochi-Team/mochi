//
//  Repos.swift
//
//
//  Created by MochiTeam on 10/5/23.
//
//

import Foundation

struct Repos: _Feature {
    var dependencies: any Dependencies {
        Architecture()
        ClipboardClient()
        ModuleClient()
        RepoClient()
        SharedModels()
        Styling()
        ViewComponents()
        ComposableArchitecture()
        NukeUI()
    }
}
