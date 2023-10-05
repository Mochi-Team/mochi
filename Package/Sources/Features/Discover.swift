//
//  Discover.swift
//  
//
//  Created by ErrorErrorError on 10/5/23.
//  
//

import Foundation

struct Discover: Feature {
    var dependencies: any Dependencies {
        Architecture()
        PlaylistDetails()
        ModuleClient()
        ModuleLists()
        RepoClient()
        Styling()
        SharedModels()
        ViewComponents()
        ComposableArchitecture()
        NukeUI()
    }
}
