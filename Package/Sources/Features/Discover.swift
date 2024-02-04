//
//  Discover.swift
//
//
//  Created by ErrorErrorError on 10/5/23.
//
//

import Foundation

struct Discover: _Feature {
    var dependencies: any Dependencies {
        Architecture()
        PlaylistDetails()
        ModuleClient()
        ModuleLists()
        RepoClient()
        Search()
        Styling()
        SharedModels()
        ViewComponents()
        ComposableArchitecture()
        NukeUI()
    }
}
