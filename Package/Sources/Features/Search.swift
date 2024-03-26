//
//  Search.swift
//
//
//  Created by ErrorErrorError on 10/5/23.
//
//

import Foundation

struct Search: _Feature {
    var dependencies: any Dependencies {
        Architecture()
        LoggerClient()
        ModuleClient()
        ModuleLists()
        PlaylistDetails()
        RepoClient()
        SharedModels()
        Styling()
        ViewComponents()
        ComposableArchitecture()
        NukeUI()
    }
}
