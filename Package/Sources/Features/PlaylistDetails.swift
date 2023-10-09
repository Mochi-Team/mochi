//
//  PlaylistDetails.swift
//  
//
//  Created by ErrorErrorError on 10/5/23.
//  
//

import Foundation

struct PlaylistDetails: Feature {
    var dependencies: any Dependencies {
        Architecture()
        ContentCore()
        LoggerClient()
        ModuleClient()
        RepoClient()
        Styling()
        SharedModels()
        ViewComponents()
        ComposableArchitecture()
        NukeUI()
    }
}
