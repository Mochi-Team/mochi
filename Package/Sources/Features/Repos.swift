//
//  Repos.swift
//  
//
//  Created by ErrorErrorError on 10/5/23.
//  
//

import Foundation

struct Repos: _Feature {
    var dependencies: any Dependencies {
        Architecture()
        ModuleClient()
        RepoClient()
        SharedModels()
        Styling()
        ViewComponents()
        ComposableArchitecture()
        NukeUI()
    }
}
